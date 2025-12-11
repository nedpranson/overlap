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

load_library_a: *@TypeOf(LoadLibraryA),
load_library_w: *@TypeOf(LoadLibraryW),

var self: ?Hooks = null;

// unordered!
const hooks_map = std.StaticStringMap(Hook).initComptime(.{
    .{ "d3d11.dll", d3d11.interface },
});

pub const Hook = struct {
    attach: fn (lib: windows.HMODULE) bool,
    detach: fn () void,
};

pub fn init() bool {
    assert(self == null);

    var failure = true;

    const kernel32 = windows.GetModuleHandle("kernel32.dll") orelse {
        std.log.err("kernel32: module not found", .{});
        return false;
    };

    detours.TransactionBegin() catch |err| {
        std.log.err("kernel32: could not begin the transaction: {}", .{err});
        return false;
    };

    var load_library_a: *@TypeOf(LoadLibraryA) = undefined;
    var load_library_w: *@TypeOf(LoadLibraryW) = undefined;

    // when adding even one more func we could do comptime magic
    // to generate these functions

    if (windows.GetProcAddress(kernel32, "LoadLibraryA")) |proc| {
        var ptr: *@TypeOf(LoadLibraryA) = @ptrCast(proc);

        detours.Attach(LoadLibraryA, &ptr) catch |err| {
            std.log.err("kernel32: LoadLibraryA: failed to attach: {}", .{err});

            detours.TransactionAbort() catch {};
            return false;
        };

        std.log.info("kernel32: LoadLibraryA: successfully attached", .{});
        load_library_a = ptr;
    } else |err| {
        std.log.err("kernel32: LoadLibraryA: failed to get proc address: {}", .{err});

        detours.TransactionAbort() catch {};
        return false;
    }

    if (windows.GetProcAddress(kernel32, "LoadLibraryW")) |proc| {
        var ptr: *@TypeOf(LoadLibraryW) = @ptrCast(proc);

        detours.Attach(LoadLibraryW, &ptr) catch |err| {
            std.log.err("kernel32: LoadLibraryW: failed to attach: {}", .{err});

            detours.TransactionAbort() catch {};
            return false;
        };

        std.log.info("kernel32: LoadLibraryW: successfully attached", .{});
        load_library_w = ptr;
    } else |err| {
        std.log.err("kernel32: LoadLibraryW: failed to get proc address: {}", .{err});

        detours.TransactionAbort() catch {};
        return false;
    }


    // every single kernel32 hook has to be established to continue execution
    // like LoadLibraryA, LoadLibraryW, Ex variants, FreeLibrary

    self = .{
        .load_library_a = load_library_a,
        .load_library_w = load_library_w,
    };

    detours.TransactionCommit() catch |err| {
        std.log.err("kernel32: could not commit the transaction: {}", .{err});

        self = null;
        return false;
    };
    defer if (failure) deinit();

    self.?.mutex.lock();
    defer self.?.mutex.unlock();

    if (windows.GetModuleHandle("d3d11.dll")) |mod| {
        _ = d3d11.attach(mod);
    }

    failure = false;
    return true;
}

pub fn deinit() void {
    const hooks = &self.?;
    defer self = null;

    blk: {
        detours.TransactionBegin() catch |err| {
            std.log.err("kernel32: could not commit the transaction: {}", .{err});
            break :blk;
        };

        if (detours.Detach(LoadLibraryA, &hooks.load_library_a)) {
            std.log.info("kernel32: LoadLibraryA: successfully deattached", .{});
        } else |err| {
            std.log.err("kernel32: LoadLibraryA: cannot detach: {}", .{err});

            detours.TransactionAbort() catch {};
            break :blk;
        }

        if (detours.Detach(LoadLibraryW, &hooks.load_library_w)) {
            std.log.info("kernel32: LoadLibraryW: successfully deattached", .{});
        } else |err| {
            std.log.err("kernel32: LoadLibraryW: cannot detach: {}", .{err});

            detours.TransactionAbort() catch {};
            break :blk;
        }

        detours.TransactionCommit() catch |err| {
            std.log.err("kernel32: could not commit the transaction: {}", .{err});
            break :blk;
        };
    }

    if (d3d11.active()) {
        d3d11.detach();
    }
}

fn LoadLibraryA(lpLibFileName: ?windows.LPCSTR) callconv(.winapi) ?windows.HMODULE {
    const hooks = &self.?;

    const lib = hooks.load_library_a(lpLibFileName) orelse return null;
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

    const lib = hooks.load_library_w(lpLibFileName) orelse return null;
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
