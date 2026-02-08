const std = @import("std");
const windows = @import("windows.zig");
const hooks = @import("hooks.zig");
const renderer = @import("renderer.zig");

const Thread = std.Thread;

pub export fn __overlap_hook_proc(code: c_int, wParam: windows.WPARAM, lParam: windows.LPARAM) callconv(.winapi) windows.LRESULT {
    return windows.user32.CallNextHookEx(null, code, wParam, lParam);
}

var exit_ev: Thread.ResetEvent = .{};
var done_ev: Thread.ResetEvent = .{};

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;

fn entry(_: ?windows.LPVOID) callconv(.winapi) windows.DWORD {
    defer done_ev.set();
    defer _ = gpa.deinit();

    if (!hooks.init(gpa.allocator())) {
        return 0;
    }

    renderer.init(gpa.allocator()) catch {
        // todo: print err
        hooks.deinit();
        return 0;
    };

    exit_ev.wait();

    // we need to ensure that noone can call `renderer.render`
    // while `renderer.deinit` is called
    // this `hooks.deinit()` should give that guarantee
    hooks.deinit();
    renderer.deinit();

    return 0;
}

pub export fn DllMain(hinstDLL: windows.HINSTANCE, fdwReason: windows.DWORD, lpvReserved: ?windows.LPVOID) callconv(.winapi) windows.BOOL {
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
        // if lpvReserved is not nil on DLL_PROCESS_DETACH
        // it means termination and we should not do cleanup
        windows.DLL_PROCESS_DETACH => if (lpvReserved == null) {
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
