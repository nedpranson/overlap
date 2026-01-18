const std = @import("std");
const windows = @import("windows.zig");
const detours = @import("detours.zig");
const hooks = @import("hooks.zig");
const renderer = @import("renderer.zig");
const atomic = std.atomic;

fn setup() bool {
    std.log.info("attaching overlay hooks");
    return hooks.init();
}

fn cleanup() void {
    std.log.info("deattaching overlay hooks");
    renderer.cleanup();
    hooks.deinit();
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
            .initialized,
            .uninitialized,
            .failure => |s| {
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
        break :blk buffer[0 .. buffer.len - 1 :0];
    };

    windows.OutputDebugString(msg);
}

pub const std_options: std.Options = .{
    .logFn = logFn,
};
