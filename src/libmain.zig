const std = @import("std");
const windows = @import("windows.zig");
const hooks = @import("hooks.zig");
const assert = std.debug.assert;

pub var wake_ev: windows.HANDLE = undefined;
pub var done_ev: windows.HANDLE = undefined;

// fn libmain(io: std.Io, gpa: std.mem.Allocator) !void {
//     // try windows.RoInitialize(.MULTITHREADED);
//     // defer windows.RoUninitialize();
//     //
//     // const manager = try windows.GlobalSystemMediaTransportControlsSessionManager.Request(io);
//     // defer manager.Release();
//     //
//     // const token = try manager.CurrentSessionChanged(gpa, {}, struct {
//     //     fn invokeFn(_: void, _: windows.GlobalSystemMediaTransportControlsSessionManager) !void {
//     //         windows.OutputDebugString("session changed!");
//     //     }
//     // }.invokeFn);
//     // defer manager.RemoveCurrentSessionChanged(token) catch unreachable;
//
//     @import("Scene.zig").main(io, gpa);
//
//     try hooks.init(io, gpa);
//     defer hooks.deinit() catch {};
//
//     assert(windows.kernel32.WaitForSingleObjectEx(wake_ev, windows.INFINITE, .FALSE) == windows.WAIT_OBJECT_0);
// }

fn entry(_: windows.LPVOID) callconv(.winapi) windows.DWORD {
    defer assert(windows.kernel32.SetEvent(done_ev) != .FALSE);

    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();

    var threaded: std.Io.Threaded = .init(debug_allocator.allocator(), .{});
    defer threaded.deinit();

    @call(.always_inline, @import("Scene.zig").main, .{ threaded.io(), debug_allocator.allocator() }) catch |err| {
        std.log.err("{t}", .{err});
        if (@errorReturnTrace()) |trace| {
            std.debug.dumpErrorReturnTrace(trace);
        }
    };

    return 0;
}

pub export fn __overlap_hook_proc(code: c_int, wParam: windows.WPARAM, lParam: windows.LPARAM) callconv(.winapi) windows.LRESULT {
    return windows.user32.CallNextHookEx(null, code, wParam, lParam);
}

pub export fn DllMain(hinstDLL: windows.HINSTANCE, fdwReason: windows.DWORD, lpvReserved: ?windows.LPVOID) callconv(.winapi) windows.BOOL {
    switch (fdwReason) {
        windows.DLL_PROCESS_ATTACH => {
            windows.DisableThreadLibraryCalls(@ptrCast(hinstDLL)) catch {};

            var ok = false;

            wake_ev = windows.kernel32.CreateEventA(null, .TRUE, .FALSE, null) orelse return .FALSE;
            defer if (!ok) windows.CloseHandle(wake_ev);

            done_ev = windows.kernel32.CreateEventA(null, .TRUE, .FALSE, null) orelse return .FALSE;
            defer if (!ok) windows.CloseHandle(done_ev);

            const thread = windows.kernel32.CreateThread(
                null,
                std.Thread.SpawnConfig.default_stack_size,
                &entry,
                null,
                0,
                null,
            ) orelse return .FALSE;

            ok = true;
            windows.CloseHandle(thread);
        },
        windows.DLL_PROCESS_DETACH => if (lpvReserved == null) {
            assert(windows.kernel32.SetEvent(wake_ev) != .FALSE);
            assert(windows.kernel32.WaitForSingleObjectEx(done_ev, windows.INFINITE, .FALSE) == windows.WAIT_OBJECT_0);

            windows.CloseHandle(done_ev);
            windows.CloseHandle(wake_ev);
        },
        else => {},
    }

    return .TRUE;
}
