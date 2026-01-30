const std = @import("std");
const windows = @import("windows.zig");
const hooks = @import("hooks.zig");
const renderer = @import("renderer.zig");
const atomic = std.atomic;

const log = std.log.scoped(.entry);
const fs = std.fs;

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;

fn setup() bool {
    const allocator = gpa.allocator();

    const app_data_dir = fs.getAppDataDir(allocator, "Overlap") catch return false;
    defer allocator.free(app_data_dir);

    fs.makeDirAbsolute(app_data_dir) catch return false;

    const log_file_path = fs.path.join(allocator, &[_][]const u8{ app_data_dir, "logs.txt" }) catch return false;
    defer allocator.free(log_file_path);

    // close file later
    const log_file = fs.openFileAbsolute(log_file_path, .{ .mode = .write_only, .lock = .exclusive }) catch return false;
    windows.SetStdHandle(windows.STD_ERROR_HANDLE, log_file.handle) catch {
        log_file.close();
        return false;
    };

    log.info("{s}\n", .{log_file_path});
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

fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    var buffer = [_]u8{'\x00'} ** 4096;
    const msg = std.fmt.bufPrintZ(&buffer, "overlap: " ++ level_txt ++ prefix2 ++ format, args) catch blk: {
        buffer[buffer.len - 1] = '\x00';
        break :blk buffer[0 .. buffer.len - 1 :0];
    };

    std.debug.print();
    windows.OutputDebugString(msg);
}

//pub const std_options: std.Options = .{
    //.logFn = logFn,
//};
