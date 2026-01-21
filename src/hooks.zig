const std = @import("std");
const windows = @import("windows.zig");
const detours = @import("detours.zig");
const d3d11 = @import("hooks/d3d11.zig");
const Image = @import("graphics/Image.zig");

const mem = std.mem;
const unicode = std.unicode;
const log = std.log.scoped(.hooks);
const Mutex = std.Thread.Mutex;
const Allocator = mem.Allocator;
const assert = std.debug.assert;

var hook_mu: Mutex.Recursive = .init;
var allocator: Allocator = undefined;

var load_library_a: *@TypeOf(LoadLibraryA) = undefined;
var load_library_w: *@TypeOf(LoadLibraryW) = undefined;

var hooked = false;

pub const hooks = [_]Hook{
    d3d11.interface,
};

pub const Hook = struct {
    module_a: [:0]const u8,
    module_w: [:0]const u16,

    attach: *const fn (allocator: Allocator, lib: windows.HMODULE) bool,
    detach: *const fn () void,
    active: *const fn () bool,
    unload_image: *const fn (img: *Image) void,

    pub const Descriptor = struct {
        attach: *const fn (allocator: Allocator, lib: windows.HMODULE) bool,
        detach: *const fn () void,
        active: *const fn () bool,
        unload_image: *const fn (img: *Image) void,
    };

    pub fn define(comptime module: [:0]const u8, desc: Descriptor) Hook {
        return .{
            .module_a = module,
            .module_w = unicode.wtf8ToWtf16LeStringLiteral(module),
            .attach = desc.attach,
            .detach = desc.detach,
            .active = desc.active,
            .unload_image = desc.unload_image,
        };
    }
};

pub fn init(gpa: Allocator) bool {
    assert(hooked == false);

    var failure = true;

    const kernel32 = windows.GetModuleHandle("kernel32.dll") orelse {
        log.err("kernel32: module not found", .{});
        return false;
    };

    defer if (failure) {
        load_library_a = undefined;
        load_library_w = undefined;
    };

    allocator = gpa;

    if (windows.GetProcAddress(kernel32, "LoadLibraryA")) |proc| {
        load_library_a = @ptrCast(proc);
        detours.attach(LoadLibraryA, &load_library_a) catch |err| {
            log.err("LoadLibraryA: failed to attach: {}", .{err});
            return false;
        };
        log.info("LoadLibraryA: successfully attached", .{});
    } else |err| {
        log.err("LoadLibraryA: failed to get proc address: {}", .{err});
        return false;
    }
    defer if (failure) detours.detach(LoadLibraryA, &load_library_a) catch |err| {
        log.err("LoadLibraryA: cannot detach: {}", .{err});
    };

    if (windows.GetProcAddress(kernel32, "LoadLibraryW")) |proc| {
        load_library_w = @ptrCast(proc);
        detours.attach(LoadLibraryW, &load_library_w) catch |err| {
            log.err("LoadLibraryW: failed to attach: {}", .{err});
            return false;
        };
        log.info("LoadLibraryW: successfully attached", .{});
    } else |err| {
        log.err("LoadLibraryW: failed to get proc address: {}", .{err});
        return false;
    }
    defer if (failure) detours.detach(LoadLibraryW, &load_library_w) catch |err| {
        log.err("LoadLibraryW: cannot detach: {}", .{err});
    };

    hook_mu.lock();
    defer hook_mu.unlock();

    for (hooks) |hook| {
        const mod = windows.GetModuleHandle(hook.module_a) orelse continue;
        if (!hook.attach(allocator, mod)) {
            log.warn("{s}: failed to hook", .{hook.module_a});
        }
    }

    failure = false;
    hooked = true;

    return true;
}

pub fn deinit() void {
    assert(hooked == true);

    defer load_library_a = undefined;
    defer load_library_w = undefined;

    if (detours.detach(LoadLibraryA, &load_library_a)) {
        log.info("LoadLibraryA: successfully detached", .{});
    } else |err| {
        log.err("LoadLibraryA: cannot detach: {}", .{err});
    }

    if (detours.detach(LoadLibraryW, &load_library_w)) {
        log.info("LoadLibraryW: successfully detached", .{});
    } else |err| {
        log.err("LoadLibraryW: cannot detach: {}", .{err});
    }

    hook_mu.lock();
    defer hook_mu.unlock();

    for (hooks) |hook| {
        if (!hook.active()) continue;
        hook.detach();
    }

    allocator = undefined;
}

pub fn broadcastUnloadImage(img: *Image) void {
    assert(img.ref_count.load(.acquire) == 0);
    // todo: fix this race condition `hooked` is unsafe!
    if (!hooked) return;

    hook_mu.lock();
    defer hook_mu.unlock();

    for (hooks) |hook| {
        if (hook.active()) {
            hook.unload_image(img);
        }
    }
}

fn LoadLibraryA(lpLibFileName: windows.LPCSTR) callconv(.winapi) ?windows.HMODULE {
    const lib = load_library_a(lpLibFileName) orelse return null;
    const lib_name = mem.span(lpLibFileName);

    hook_mu.lock();
    defer hook_mu.unlock();

    for (hooks) |hook| {
        if (hook.active()) continue;
        if (!mem.eql(u8, lib_name, hook.module_a)) continue;

        if (!hook.attach(allocator, lib)) {
            log.warn("{s}: failed to hook", .{hook.module_a});
        }
    }

    return lib;
}

fn LoadLibraryW(lpLibFileName: windows.LPCWSTR) callconv(.winapi) ?windows.HMODULE {
    const lib = load_library_w(lpLibFileName) orelse return null;
    const lib_name = mem.span(lpLibFileName);

    hook_mu.lock();
    defer hook_mu.unlock();

    for (hooks) |hook| {
        if (hook.active()) continue;
        if (!mem.eql(u16, lib_name, hook.module_w)) continue;

        if (!hook.attach(allocator, lib)) {
            log.warn("{s}: failed to hook", .{hook.module_a});
        }
    }

    return lib;
}
