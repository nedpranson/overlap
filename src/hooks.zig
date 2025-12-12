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

var mutex: Mutex = .{};

var load_library_a: *@TypeOf(LoadLibraryA) = undefined;
var load_library_w: *@TypeOf(LoadLibraryW) = undefined;

var hooked = false;

pub const Hook = struct {
    attach: fn (lib: windows.HMODULE) bool,
    detach: fn () void,
};

pub fn init() bool {
    assert(hooked == false);

    var failure = true;

    const kernel32 = windows.GetModuleHandle("kernel32.dll") orelse {
        std.log.err("kernel32: module not found", .{});
        return false;
    };

    defer if (failure) {
        load_library_a = undefined;
        load_library_w = undefined;
    };

    if (windows.GetProcAddress(kernel32, "LoadLibraryA")) |proc| {
        load_library_a = @ptrCast(proc);
        detours.attach(LoadLibraryA, &load_library_a) catch |err| {
            std.log.err("kernel32: LoadLibraryA: failed to attach: {}", .{err});
            return false;
        };
        std.log.info("kernel32: LoadLibraryA: successfully attached", .{});
    } else |err| {
        std.log.err("kernel32: LoadLibraryA: failed to get proc address: {}", .{err});
        return false;
    }
    defer if (failure) detours.detach(LoadLibraryA, &load_library_a) catch |err| {
        std.log.err("kernel32: LoadLibraryA: cannot detach: {}", .{err});
    };

    if (windows.GetProcAddress(kernel32, "LoadLibraryW")) |proc| {
        load_library_w = @ptrCast(proc);
        detours.attach(LoadLibraryW, &load_library_w) catch |err| {
            std.log.err("kernel32: LoadLibraryW: failed to attach: {}", .{err});
            return false;
        };
        std.log.info("kernel32: LoadLibraryW: successfully attached", .{});
    } else |err| {
        std.log.err("kernel32: LoadLibraryW: failed to get proc address: {}", .{err});
        return false;
    }
    defer if (failure) detours.detach(LoadLibraryW, &load_library_w) catch |err| {
        std.log.err("kernel32: LoadLibraryW: cannot detach: {}", .{err});
    };

    mutex.lock();
    defer mutex.unlock();

    if (windows.GetModuleHandle("d3d11.dll")) |mod| {
        _ = d3d11.attach(mod);
    }

    failure = false;
    hooked = true;

    return true;
}

pub fn deinit() void {
    assert(hooked == true);
    
    defer load_library_a = undefined;
    defer load_library_w = undefined;

    detours.detach(LoadLibraryA, &load_library_a) catch |err| {
        std.log.err("kernel32: LoadLibraryA: cannot detach: {}", .{err});
    };

    detours.detach(LoadLibraryW, &load_library_w) catch |err| {
        std.log.err("kernel32: LoadLibraryW: cannot detach: {}", .{err});
    };

    if (d3d11.active()) {
        d3d11.detach();
    }
}

fn LoadLibraryA(lpLibFileName: ?windows.LPCSTR) callconv(.winapi) ?windows.HMODULE {
    const lib = load_library_a(lpLibFileName) orelse return null;
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
    const lib = load_library_w(lpLibFileName) orelse return null;
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
