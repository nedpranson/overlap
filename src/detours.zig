const windows = @import("windows.zig");
const Win32Error = windows.Win32Error;

extern fn DetourTransactionBegin() callconv(.c) windows.LONG;
extern fn DetourUpdateThread(hThread: windows.HANDLE) callconv(.c) windows.LONG;
extern fn DetourAttach(ppPointer: *windows.LPVOID, pDetour: windows.LPCVOID) callconv(.c) windows.LONG;
extern fn DetourDetach(ppPointer: *windows.LPVOID, pDetour: windows.LPCVOID) callconv(.c) windows.LONG;
extern fn DetourTransactionCommit() callconv(.c) windows.LONG;
extern fn DetourTransactionAbort() callconv(.c) windows.LONG;

pub const TransactionBeginError = error{
    PendingTransaction,
    Unexpected,
};

pub fn TransactionBegin() TransactionBeginError!void {
    const win_err: Win32Error = @enumFromInt(DetourTransactionBegin());
    return switch (win_err) {
        .SUCCESS => {},
        @as(Win32Error, @enumFromInt(4317)) => return error.PendingTransaction, // ERROR_INVALID_OPERATION
        else => |e| return windows.unexpectedError(e),
    };
}

pub const TransactionCommitrror = error{
    Modified,
    NoPendingTransaction,
    FunctionTooSmall,
    OutOfMemory,
    Unexpected,
};

pub fn TransactionCommit() TransactionCommitrror!void {
    const win_err: Win32Error = @enumFromInt(DetourTransactionCommit());
    return switch (win_err) {
        .SUCCESS => {},
        .INVALID_DATA => error.Modified,
        .INVALID_BLOCK => error.FunctionTooSmall,
        .INVALID_HANDLE => unreachable,
        @as(Win32Error, @enumFromInt(4317)) => return error.NoPendingTransaction, // ERROR_INVALID_OPERATION
        .NOT_ENOUGH_MEMORY => error.OutOfMemory,
        else => |e| return windows.unexpectedError(e),
    };
}

pub const TransactionAbortError = error{
    NoPendingTransaction,
    Unexpected,
};

pub fn TransactionAbort() TransactionAbortError!void {
    const win_err: Win32Error = @enumFromInt(DetourTransactionAbort());
    return switch (win_err) {
        .SUCCESS => {},
        @as(Win32Error, @enumFromInt(4317)) => return error.NoPendingTransaction, // ERROR_INVALID_OPERATION
        else => |e| return windows.unexpectedError(e),
    };
}

pub const AttachError = error{
    NoPendingTransaction,
    FunctionTooSmall,
    OutOfMemory,
    Unexpected,
};

pub fn Attach(comptime Detour: anytype, ppPointer: **@TypeOf(Detour)) AttachError!void {
    const win_err: Win32Error = @enumFromInt(DetourAttach(ppPointer, &Detour));
    return switch (win_err) {
        .SUCCESS => {},
        .INVALID_BLOCK => error.FunctionTooSmall,
        .INVALID_HANDLE => unreachable,
        @as(Win32Error, @enumFromInt(4317)) => return error.NoPendingTransaction, // ERROR_INVALID_OPERATION
        .NOT_ENOUGH_MEMORY => error.OutOfMemory,
        else => |e| return windows.unexpectedError(e),
    };
}

pub const DetachError = error{
    NoPendingTransaction,
    FunctionTooSmall,
    OutOfMemory,
    Unexpected,
};

pub fn Detach(comptime Detour: anytype, ppPointer: **@TypeOf(Detour)) DetachError!void {
    const win_err: Win32Error = @enumFromInt(DetourDetach(ppPointer, &Detour));
    return switch (win_err) {
        .SUCCESS => {},
        .INVALID_BLOCK => error.FunctionTooSmall,
        .INVALID_HANDLE => unreachable,
        @as(Win32Error, @enumFromInt(4317)) => return error.NoPendingTransaction, // ERROR_INVALID_OPERATION
        .NOT_ENOUGH_MEMORY => error.OutOfMemory,
        else => |e| return windows.unexpectedError(e),
    };
}
