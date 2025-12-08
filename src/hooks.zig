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
established_hooks: EstablishedHooks = .{},

load_library_a: ?*@TypeOf(LoadLibraryA),
load_library_w: ?*@TypeOf(LoadLibraryW),

var self: ?Hooks = null;

// we could have like a static "hash_map" with set keys and values as a pointer
const EstablishedHooks = packed struct {
    d3d11: bool = false,
};

pub fn init() bool {
    assert(self == null);

    const kernel32 = windows.GetModuleHandle("kernel32") orelse {
        std.log.err("kernel32: module not found", .{});
        return true;
    };

    var load_library_a: ?*@TypeOf(LoadLibraryA) = @ptrCast(windows.GetProcAddress(kernel32, "LoadLibraryA") catch |err| blk: {
        std.log.err("LoadLibraryA: failed to get proc address: {}", .{err});
        break :blk null;
    });

    if (load_library_a) |*func| blk: {
        detours.attach(LoadLibraryA, func) catch |err| {
            std.log.err("LoadLibraryA: failed to attach: {}", .{err});
            load_library_a = null;
            break :blk;
        };
        std.log.info("LoadLibraryA: successfully attached", .{});
    }

    var load_library_w: ?*@TypeOf(LoadLibraryW) = @ptrCast(windows.GetProcAddress(kernel32, "LoadLibraryW") catch |err| blk: {
        std.log.err("LoadLibraryW: failed to get proc address: {}", .{err});
        break :blk null;
    });

    if (load_library_w) |*func| blk: {
        detours.attach(LoadLibraryW, func) catch |err| {
            std.log.err("LoadLibraryW: failed to attach: {}", .{err});
            load_library_w = null;
            break :blk;
        };
        std.log.info("LoadLibraryW: successfully attached", .{});
    }

    self = .{
        .load_library_a = load_library_a,
        .load_library_w = load_library_w,
    };

    if (load_library_a == null and load_library_w == null) {
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
            std.log.err("LoadLibraryA: cannot detach: {}", .{err});
            break :blk;
        };
        std.log.info("LoadLibraryA: successfully deattached", .{});
    }

    if (hooks.load_library_w) |*func| blk: {
        detours.detach(LoadLibraryW, func) catch |err| {
            std.log.err("LoadLibraryW: cannot detach: {}", .{err});
            break :blk;
        };
        std.log.info("LoadLibraryW: successfully deattached", .{});
    }
}

fn LoadLibraryA(lpLibFileName: ?windows.LPCSTR) callconv(.winapi) ?windows.HMODULE {
    const hooks = &self.?;

    const lib = hooks.load_library_a.?(lpLibFileName) orelse return null;
    const lib_name = mem.span(lpLibFileName orelse unreachable);

    std.log.debug("{s}", .{lib_name});

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
    const lib_name = mem.span(lpLibFileName orelse unreachable);

    std.log.debug("{f}", .{std.unicode.fmtUtf16Le(lib_name)});

    //if (mem.eql(u16, lib_name, unicode.wtf8ToWtf16LeStringLiteral("d3d11.dll"))) {
        //hooks.mutex.lock();
        //defer hooks.mutex.unlock();

        //const window = makeDummyWindow() catch unreachable;
        //defer windows.DestroyWindow(window);

        //d3d11.attach(lib, window, &hooks.mutex) catch unreachable;
    //}

    return lib;
}

/// Returned handle should be destroyed with `windows.DestroyWindow` when no longer used.
fn makeDummyWindow() windows.CreateWindowExError!windows.HWND {
    return windows.CreateWindowEx(
        0,
        "STATIC",
        "Overlap Dummy Window",
        windows.WS_OVERLAPPEDWINDOW,
        windows.CW_USEDEFAULT,
        windows.CW_USEDEFAULT,
        640,
        480,
        null,
        null,
        null,
        null,
    );
}
