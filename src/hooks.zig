const std = @import("std");
const windows = @import("windows.zig");
const graphics = @import("graphics.zig");
const d3d11 = @import("hooks/d3d11.zig");
const Gui = @import("Gui2.zig");
const detours = @import("detours.zig");

const mem = std.mem;
const unicode = std.unicode;
const Mutex = std.Thread.Mutex;
const assert = std.debug.assert;

const Hooks = @This();

mutex: Mutex = .{},

load_library_a: ?*@TypeOf(LoadLibraryA),
load_library_w: ?*@TypeOf(LoadLibraryW),

var self: ?Hooks = null;

// unordered!
const hooks_map = std.StaticStringMap(Hook).initComptime(.{
    .{ "d3d11.dll", d3d11.interface },
});

pub const Hook = struct {
    attach: fn(lib: windows.HMODULE) bool,
    detach: fn () void,
};

// hook FreeLibrary too!
pub fn init() bool {
    assert(self == null);

    var successes: std.math.IntFittingRange(0, hooks_map.keys().len + 2) = 0;

    const kernel32 = windows.GetModuleHandle("kernel32") orelse {
        std.log.err("kernel32: module not found", .{});
        return true;
    };

    var load_library_a: ?*@TypeOf(LoadLibraryA) = @ptrCast(windows.GetProcAddress(kernel32, "LoadLibraryA") catch |err| blk: {
        std.log.err("kernel32: LoadLibraryA: failed to get proc address: {}", .{err});
        break :blk null;
    });

    if (load_library_a) |*func| blk: {
        detours.attach(LoadLibraryA, func) catch |err| {
            std.log.err("kernel32: LoadLibraryA: failed to attach: {}", .{err});
            load_library_a = null;
            break :blk;
        };
        std.log.info("kernel32: LoadLibraryA: successfully attached", .{});
        successes += 1;
    }

    var load_library_w: ?*@TypeOf(LoadLibraryW) = @ptrCast(windows.GetProcAddress(kernel32, "LoadLibraryW") catch |err| blk: {
        std.log.err("kernel32: LoadLibraryW: failed to get proc address: {}", .{err});
        break :blk null;
    });

    if (load_library_w) |*func| blk: {
        detours.attach(LoadLibraryW, func) catch |err| {
            std.log.err("LoadLibraryW: failed to attach: {}", .{err});
            load_library_w = null;
            break :blk;
        };
        std.log.info("kernel32: LoadLibraryW: successfully attached", .{});
        successes += 1;
    }

    // inline for (comptime hooks_map.keys()) |lib_name| {
        //const lib_name_z = (lib_name ++ "\x00")[0..lib_name.len: 0];
        //const hook_name = lib_name[0..lib_name.len - 4];

        //if (windows.GetModuleHandle(lib_name_z)) |mod| {
            //const hook = comptime hooks_map.get(lib_name).?;
            //if (hook.attach(mod)) {
                //std.log.info(hook_name ++ ": failed to hook", .{});
            //} else {
                //std.log.info(hook_name ++ ": successfully hooked", .{});
                //successes += 1;
            //}
        //}
    //}

    self = .{
        .load_library_a = load_library_a,
        .load_library_w = load_library_w,
    };

    if (successes == 0) {
        deinit();
        return true;
    }

    return false;
}

pub fn deinit() void {
    const hooks = &self.?;
    defer self = null;

    if (hooks.load_library_a) |*func| blk: {
        detours.detach(LoadLibraryA, func) catch |err| {
            std.log.err("kernel32: LoadLibraryA: cannot detach: {}", .{err});
            break :blk;
        };
        std.log.info("kernel32: LoadLibraryA: successfully deattached", .{});
    }

    if (hooks.load_library_w) |*func| blk: {
        detours.detach(LoadLibraryW, func) catch |err| {
            std.log.err("kernel32: LoadLibraryW: cannot detach: {}", .{err});
            break :blk;
        };
        std.log.info("kernel32: LoadLibraryW: successfully deattached", .{});
    }

    // inline for (comptime hooks_map.values()) |hook| {
        // hook.detach();
    // }
}

fn LoadLibraryA(lpLibFileName: ?windows.LPCSTR) callconv(.winapi) ?windows.HMODULE {
    const hooks = &self.?;

    const lib = hooks.load_library_a.?(lpLibFileName) orelse return null;
    //const lib_name = mem.span(lpLibFileName orelse unreachable);

    //std.log.debug("{s}", .{lib_name});

    //if (mem.eql(u8, lib_name, "d3d11.dll")) {
        //hooks.mutex.lock();
        //defer hooks.mutex.unlock();

        //const window = makeDummyWindow() catch unreachable;
        //defer windows.DestroyWindow(window);

        //d3d11.attach(lib, window, &hooks.mutex) catch unreachable;
    //}

    return lib;
}

fn LoadLibraryW(lpLibFileName: ?windows.LPCWSTR) callconv(.winapi) ?windows.HMODULE {
    const hooks = &self.?;

    const lib = hooks.load_library_w.?(lpLibFileName) orelse return null;
    //const lib_name = mem.span(lpLibFileName orelse unreachable);

    //std.log.debug("{f}", .{std.unicode.fmtUtf16Le(lib_name)});

    //if (mem.eql(u16, lib_name, unicode.wtf8ToWtf16LeStringLiteral("d3d11.dll"))) {
        //hooks.mutex.lock();
        //defer hooks.mutex.unlock();

        //const window = makeDummyWindow() catch unreachable;
        //defer windows.DestroyWindow(window);

        //d3d11.attach(lib, window, &hooks.mutex) catch unreachable;
    //}

    return lib;
}
