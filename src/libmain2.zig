const std = @import("std");
const windows = @import("windows.zig");
const detours = @import("detours.zig");
const hooks = @import("hooks.zig");

// maybe return like an error.Failed or smth so cleanup would not be called
fn setup() bool {
    std.log.info("prepare them hooks and state...", .{});

    if (hooks.init()) return true;

    return false;
}

fn cleanup() void {
    std.log.info("restore modified state...", .{});
    hooks.deinit();
}

var enabled: std.atomic.Value(bool) = .init(false);

var mutex: std.Thread.Mutex = .{};
var failure = false;

pub export fn __overlap_hook_proc(code: c_int, wParam: windows.WPARAM, lParam: windows.LPARAM) callconv(.winapi) windows.LRESULT {
    if (isTargetProcess() and enabled.cmpxchgStrong(false, true, .acq_rel, .monotonic) == null) {
        mutex.lock();
        defer mutex.unlock();

        failure = @call(.always_inline, setup, .{});
    }

    return windows.user32.CallNextHookEx(null, code, wParam, lParam);
}

pub export fn DllMain(hinstDLL: windows.HINSTANCE, fdwReason: windows.DWORD, lpvReserved: windows.LPVOID) callconv(.winapi) windows.BOOL {
    _ = hinstDLL;
    _ = lpvReserved;

    if (fdwReason == windows.DLL_PROCESS_DETACH and isTargetProcess() and enabled.load(.acquire)) {
        mutex.lock();
        defer mutex.unlock();

        if (!failure) {
            // calling winapi inside DllMain is 'forbidden'
            @call(.always_inline, cleanup, .{});
        }
    }

    return windows.TRUE;
}

fn isTargetProcess() bool {
    if (windows.GetModuleHandle(null)) |handle| {
        _ = windows.GetProcAddress(handle, "__overlap_ignore_proc") catch return true;
    }
    return false;
}

fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    var buffer = [_]u8{'\x00'} ** 4096;
    const msg = std.fmt.bufPrintZ(&buffer, level_txt ++ prefix2 ++ format, args) catch blk: {
        buffer[buffer.len - 1] = '\x00';
        break :blk buffer[0..buffer.len - 1:0];
    };

    windows.OutputDebugString(msg);
}

pub const std_options: std.Options = .{
    .logFn = logFn,
};
