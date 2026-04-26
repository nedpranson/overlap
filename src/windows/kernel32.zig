const std = @import("std");
const windows = @import("../windows.zig");

const BOOL = windows.BOOL;
const DWORD = windows.DWORD;
const HANDLE = windows.HANDLE;
const SIZE_T = windows.SIZE_T;
const LPCSTR = windows.LPCSTR;
const LPVOID = windows.LPVOID;
const LPCWSTR = windows.LPCWSTR;
const HMODULE = windows.HMODULE;
const FARPROC = windows.FARPROC;
const SECURITY_ATTRIBUTES = windows.SECURITY_ATTRIBUTES;
const LPSECURITY_ATTRIBUTES = windows.LPSECURITY_ATTRIBUTES;
const LPTHREAD_START_ROUTINE = windows.LPTHREAD_START_ROUTINE;

pub extern "kernel32" fn CreateThread(
    lpThreadAttributes: ?LPSECURITY_ATTRIBUTES,
    dwStackSize: SIZE_T,
    lpStartAddress: LPTHREAD_START_ROUTINE,
    lpParameter: ?LPVOID,
    dwCreationFlags: DWORD,
    lpThreadId: ?*DWORD,
) callconv(.winapi) ?HANDLE;

pub extern "kernel32" fn WaitForSingleObjectEx(
    hHandle: HANDLE,
    dwMilliseconds: DWORD,
    bAlertable: BOOL,
) callconv(.winapi) DWORD;

pub extern "kernel32" fn WaitForMultipleObjects(
    nCount: DWORD,
    lpHandle: [*]const HANDLE,
    bWaitAll: BOOL,
    dwMilliseconds: DWORD,
) callconv(.winapi) DWORD;

pub extern "kernel32" fn CreateEventA(
    lpEventAttributes: ?LPSECURITY_ATTRIBUTES,
    bManualReset: BOOL,
    bInitialState: BOOL,
    lpName: ?LPCSTR,
) callconv(.winapi) ?HANDLE;

pub extern "kernel32" fn SetEvent(hEvent: HANDLE) callconv(.winapi) BOOL;

pub extern "kernel32" fn SetStdHandle(nStdHandle: DWORD, hHandle: HANDLE) callconv(.winapi) BOOL;

pub extern "kernel32" fn DisableThreadLibraryCalls(hLibModule: HMODULE) callconv(.winapi) BOOL;

pub extern "kernel32" fn AllocConsole() callconv(.winapi) BOOL;

pub extern "kernel32" fn FreeConsole() callconv(.winapi) BOOL;

pub extern "kernel32" fn FreeLibraryAndExitThread(hLibModule: HMODULE, dwExitCode: DWORD) callconv(.winapi) noreturn;

pub extern "kernel32" fn GetModuleHandleA(lpModuleName: ?LPCSTR) callconv(.winapi) ?HMODULE;

pub extern "kernel32" fn GetProcAddress(hModule: HMODULE, lpProcName: LPCSTR) callconv(.winapi) ?FARPROC;

pub extern "kernel32" fn SetConsoleTitleA(lpConsoleTitle: LPCSTR) callconv(.winapi) BOOL;

pub extern "kernel32" fn OutputDebugStringA(lpOutputString: LPCSTR) callconv(.winapi) void;

pub extern "kernel32" fn OutputDebugStringW(lpOutputString: LPCWSTR) callconv(.winapi) void;
