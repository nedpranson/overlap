const std = @import("std");
const windows = @import("windows.zig");

const Thread = std.Thread;

pub export fn __overlap_hook_proc(code: c_int, wParam: windows.WPARAM, lParam: windows.LPARAM) callconv(.winapi) windows.LRESULT {
    return windows.user32.CallNextHookEx(null, code, wParam, lParam);
}

var exit_ev: Thread.ResetEvent = .{};
var done_ev: Thread.ResetEvent = .{};

fn entry(_: windows.LPVOID) callconv(.winapi) windows.DWORD {
    defer done_ev.set();

    // setup
    windows.OutputDebugString("hello from entry thread");

    exit_ev.wait();

    // cleanup
    windows.OutputDebugString("bye from entry thread");
    return 0;
}

// DllMain is serialized
pub export fn DllMain(hinstDLL: windows.HINSTANCE, fdwReason: windows.DWORD, lpvReserved: ?windows.LPVOID) callconv(.winapi) windows.BOOL {
    _ = lpvReserved;

    const pid = windows.GetCurrentProcessId();
    const tid = windows.GetCurrentThreadId();

    var buf: [512]u8 = undefined;
    const msg = std.fmt.bufPrintZ(&buf, "pid: {d}, tid: {d}, fdwReason: {d}", .{pid, tid, fdwReason}) catch unreachable;
    windows.OutputDebugString(msg);

    switch (fdwReason) {
        windows.DLL_PROCESS_ATTACH => {
            windows.DisableThreadLibraryCalls(@ptrCast(hinstDLL)) catch {};

            const thread = windows.CreateThread(
                null,
                Thread.SpawnConfig.default_stack_size,
                &entry,
                null,
                0,
                null,
            ) catch return windows.FALSE;
            windows.CloseHandle(thread);
        },
        windows.DLL_PROCESS_DETACH => {
            exit_ev.set();
            done_ev.wait();
        },
        else => {},
    }

    return windows.TRUE;
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
    _ = format;
    _ = prefix2;
    _ = args;
}

pub const std_options: std.Options = .{
    .logFn = logFn,
};
