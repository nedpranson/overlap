const std = @import("std");
const windows = @import("windows.zig");
const hooks = @import("hooks.zig");
const renderer = @import("renderer.zig");
const atomic = std.atomic;

const Io = std.Io;
const log = std.log.scoped(.entry);
const fs = std.fs;

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;

fn setup() bool {
    const allocator = gpa.allocator();

    const wnd = windows.FindWindow("OverlapLauncherClass", null) orelse return false;
    const tid, _ = windows.GetWindowThreadProcessId(wnd) catch return false;

    const WM_HOOKNOTIFY = windows.WM_USER + 2;
    windows.PostThreadMessage(tid, WM_HOOKNOTIFY, windows.GetCurrentProcessId(), 0) catch return false;

    log.info("attaching overlay hooks", .{});
    return hooks.init(allocator);
}

fn cleanup() void {
    log.info("detaching overlay hooks", .{});
    renderer.cleanup();
    hooks.deinit();

    _ = gpa.deinit();
}

const State = enum(u8) {
    initialized,
    initializing,
    failure,
    uninitialized,
};

var state: atomic.Value(State) = .init(.uninitialized);

pub export fn __overlap_hook_proc(code: c_int, wParam: windows.WPARAM, lParam: windows.LPARAM) callconv(.winapi) windows.LRESULT {
    if (isTargetProcess() and state.cmpxchgStrong(.uninitialized, .initializing, .acq_rel, .monotonic) == null) {
        const s: State = if (@call(.always_inline, setup, .{})) .initialized else .failure;
        state.store(s, .release);
    }

    return windows.user32.CallNextHookEx(null, code, wParam, lParam);
}

pub export fn DllMain(hinstDLL: windows.HINSTANCE, fdwReason: windows.DWORD, lpvReserved: windows.LPVOID) callconv(.winapi) windows.BOOL {
    _ = hinstDLL;
    _ = lpvReserved;

    if (fdwReason != windows.DLL_PROCESS_DETACH) return windows.TRUE;

    while (true) {
        switch (state.load(.acquire)) {
            .initializing => atomic.spinLoopHint(),
            .initialized, .uninitialized, .failure => |s| {
                if (s == .initialized) @call(.always_inline, cleanup, .{});
                return windows.TRUE;
            },
        }
    }
}

fn isTargetProcess() bool {
    if (windows.GetModuleHandle(null)) |handle| {
        _ = windows.GetProcAddress(handle, "__overlap_ignore_proc") catch return true;
    }
    return false;
}

fn openAppDataDir(alloc: std.mem.Allocator, appname: []const u8) !fs.Dir {
    const path = try fs.getAppDataDir(alloc, appname);
    defer alloc.free(path);

    while (true) {
        return fs.openDirAbsolute(path, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                fs.makeDirAbsolute(path) catch |err2| switch (err2) {
                    error.PathAlreadyExists => {},
                    else => |e| return e,
                };

                continue;
            },
            else => |e| return e,
        };
    }
}


fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    _ = level_txt;
    _ = prefix2;
    _ = format;
    _ = args;
}

pub const std_options: std.Options = .{
    .logFn = logFn,
};
