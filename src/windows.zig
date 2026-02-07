const std = @import("std");
const builtin = @import("builtin");

const target = builtin.target;
const windows = std.os.windows;
const unicode = std.unicode;
const assert = std.debug.assert;
const mem = std.mem;
const graphics = @import("windows/graphics.zig");
const media = @import("windows/media.zig");
const psapi = @import("windows/psapi.zig");
const winhttp = @import("windows/winhttp.zig");
const winrt = @import("windows/winrt.zig");
const Allocator = mem.Allocator;

pub const kernel32 = @import("windows/kernel32.zig");
pub const combase = @import("windows/combase.zig");
pub const user32 = @import("windows/user32.zig");
pub const dxgi = @import("windows/dxgi.zig");
pub const d3d11 = @import("windows/d3d11.zig");
pub const d3dcommon = @import("windows/d3dcommon.zig");
pub const d3dcompiler = @import("windows/d3dcompiler.zig");

pub const Win32Error = windows.Win32Error;
pub const INT = windows.INT;
pub const PVOID = windows.PVOID;
pub const LONG = windows.LONG;
pub const UINT = windows.UINT;
pub const S_OK = windows.S_OK;
pub const TRUE = windows.TRUE;
pub const HWND = windows.HWND;
pub const GUID = windows.GUID;
pub const BOOL = windows.BOOL;
pub const RECT = windows.RECT;
pub const BYTE = windows.BYTE;
pub const FLOAT = windows.FLOAT;
pub const FALSE = windows.FALSE;
pub const ULONG = windows.ULONG;
pub const DWORD = windows.DWORD;
pub const WPARAM = windows.WPARAM;
pub const PCWSTR = windows.PCWSTR;
pub const LPARAM = windows.LPARAM;
pub const SIZE_T = windows.SIZE_T;
pub const LPCSTR = windows.LPCSTR;
pub const LPSTR = windows.LPSTR;
pub const LPDWORD = *windows.DWORD;
pub const HANDLE = windows.HANDLE;
pub const LPCWSTR = windows.LPCWSTR;
pub const LRESULT = windows.LRESULT;
pub const HMODULE = windows.HMODULE;
pub const HRESULT = windows.HRESULT;
pub const LPVOID = windows.LPVOID;
pub const LPCVOID = windows.LPCVOID;
pub const LONG_PTR = windows.LONG_PTR;
pub const ULONG_PTR = windows.ULONG_PTR;
pub const HINSTANCE = windows.HINSTANCE;
pub const HRESULT_CODE = windows.HRESULT_CODE;
pub const E_NOINTERFACE = windows.E_NOINTERFACE;
pub const STD_INPUT_HANDLE = windows.STD_INPUT_HANDLE;
pub const STD_OUTPUT_HANDLE = windows.STD_OUTPUT_HANDLE;
pub const STD_ERROR_HANDLE = windows.STD_ERROR_HANDLE;
pub const SECURITY_ATTRIBUTES = windows.SECURITY_ATTRIBUTES;
pub const LPTHREAD_START_ROUTINE = windows.LPTHREAD_START_ROUTINE;
pub const INFINITE = windows.INFINITE;

pub const GetCurrentProcessId = windows.GetCurrentProcessId;
pub const GetCurrentThreadId = windows.GetCurrentThreadId;
pub const unexpectedError = windows.unexpectedError;
pub const FindWindowExA = user32.FindWindowExA;
pub const GetWindow = user32.GetWindow;
pub const GetAncestor = user32.GetAncestor;
pub const EnumWindows = user32.EnumWindows;
pub const GetCurrentThread = windows.GetCurrentThread;
pub const CloseHandle = windows.CloseHandle;
pub const WaitForSingleObject = windows.WaitForSingleObject;
pub const WaitForSingleObjectEx = windows.WaitForSingleObjectEx;

pub const COPYDATASTRUCT = extern struct {
    dwData: ULONG_PTR,
    cbData: DWORD,
    lpData: PVOID,
};

pub const TimeSpan = extern struct {
    Duration: i64,
};

pub const BitmapBounds = extern struct {
    X: u32,
    Y: u32,
    Width: u32,
    Height: u32,
};

pub const MediaPlaybackStatus = enum(INT) {
    Closed,
    Opened,
    Changing,
    Stopped,
    Playing,
    Paused,
};

const IBitmapFrame = graphics.IBitmapFrame;
const IBitmapDecoder = graphics.IBitmapDecoder;
const IBitmapDecoderStatics = graphics.IBitmapDecoderStatics;
const IRandomAccessStreamReference = winrt.IRandomAccessStreamReference;
const IPlaybackInfoChangedEventArgs = media.IPlaybackInfoChangedEventArgs;
const ICurrentSessionChangedEventArgs = media.ICurrentSessionChangedEventArgs;
const IAsyncOperationCompletedHandler = winrt.IAsyncOperationCompletedHandler;
const IMediaPropertiesChangedEventArgs = media.IMediaPropertiesChangedEventArgs;
const IRandomAccessStreamWithContentType = winrt.IRandomAccessStreamWithContentType;
const ITimelinePropertiesChangedEventArgs = media.ITimelinePropertiesChangedEventArgs;
const IAsyncOperationCompletedHandlerVTable = winrt.IAsyncOperationCompletedHandlerVTable;
const IGlobalSystemMediaTransportControlsSession = media.IGlobalSystemMediaTransportControlsSession;
const IGlobalSystemMediaTransportControlsSessionManager = media.IGlobalSystemMediaTransportControlsSessionManager;
const IGlobalSystemMediaTransportControlsSessionPlaybackInfo = media.IGlobalSystemMediaTransportControlsSessionPlaybackInfo;
const IGlobalSystemMediaTransportControlsSessionManagerStatics = media.IGlobalSystemMediaTransportControlsSessionManagerStatics;
const IGlobalSystemMediaTransportControlsSessionMediaProperties = media.IGlobalSystemMediaTransportControlsSessionMediaProperties;
const IGlobalSystemMediaTransportControlsSessionTimelineProperties = media.IGlobalSystemMediaTransportControlsSessionTimelineProperties;
const IPixelDataProvider = graphics.IPixelDataProvider;

pub const IBitmapTransform = graphics.IBitmapTransform;
pub const BitmapInterpolationMode = graphics.BitmapInterpolationMode;

pub const GW_OWNER = 4;
pub const GA_ROOT = 2;

pub const RO_INIT_TYPE = INT;
pub const RO_INIT_SINGLETHREADED = 0;
pub const RO_INIT_MULTITHREADED = 1;

pub const UINT32 = u32;
pub const HSTRING = *opaque {};
pub const HHOOK = *opaque {};
pub const NTSTATUS = windows.NTSTATUS;
pub const HMENU = windows.HMENU;
pub const PCNZWCH = windows.PCWSTR;
pub const REFIID = *const windows.GUID;
pub const HINTERNET = winhttp.HINTERNET;
pub const INTERNET_PORT = winhttp.INTERNET_PORT;
pub const IAsyncOperation = winrt.IAsyncOperation;
pub const TypedEventHandler = winrt.TypedEventHandler;
pub const IAsyncInfo = winrt.IAsyncInfo;
pub const AsyncStatus = winrt.AsyncStatus;
pub const Callback = winrt.Callback;
pub const Callback2 = winrt.Callback2;
pub const LPUNKNOWN = **IUnknown;

pub const WM_COPYDATA = 0x004A;
pub const WM_MOUSEMOVE = 0x0200;
pub const WM_LBUTTONDOWN = 0x0201;
pub const WM_LBUTTONUP = 0x0202;
pub const WM_RBUTTONDOWN = 0x0204;
pub const WM_RBUTTONUP = 0x0205;
pub const WM_USER = 0x0400;

pub const HSTRING_HEADER = extern union {
    Reserved1: PVOID,
    Reserved2: [if (target.ptrBitWidth() == 64) 24 else 20]u8,
};

pub const WNDPROC = *const fn (
    hWnd: HWND,
    uMsg: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(.winapi) LRESULT;

pub const WNDENUMPROC = *const fn (
    hwnd: HWND,
    lParam: LPARAM,
) callconv(.winapi) BOOL;

pub const BitmapPixelFormat = INT;
pub const BitmapPixelFormat_Rgba8 = 30;

pub const BitmapAlphaMode = INT;
pub const BitmapAlphaMode_Premultiplied = 0;
pub const BitmapAlphaMode_Straight = 1;
pub const BitmapAlphaMode_Ignore = 2;

pub const ExifOrientationMode = INT;
pub const ExifOrientationMode_IgnoreExifOrientation = 0;

pub const ColorManagementMode = INT;
pub const ColorManagementMode_DoNotColorManage = 0;

pub const WS_BORDER = 0x00800000;
pub const WS_CAPTION = 0x00C00000;
pub const WS_CHILD = 0x40000000;
pub const WS_CHILDWINDOW = 0x40000000;
pub const WS_CLIPCHILDREN = 0x02000000;
pub const WS_CLIPSIBLINGS = 0x04000000;
pub const WS_DISABLED = 0x08000000;
pub const WS_DLGFRAME = 0x00400000;
pub const WS_GROUP = 0x00020000;
pub const WS_HSCROLL = 0x00100000;
pub const WS_ICONIC = 0x20000000;
pub const WS_MAXIMIZE = 0x01000000;
pub const WS_MAXIMIZEBOX = 0x00010000;
pub const WS_MINIMIZE = 0x20000000;
pub const WS_MINIMIZEBOX = 0x00020000;
pub const WS_OVERLAPPED = 0x00000000;
pub const WS_POPUP = 0x80000000;
pub const WS_SIZEBOX = 0x00040000;
pub const WS_SYSMENU = 0x00080000;
pub const WS_TABSTOP = 0x00010000;
pub const WS_THICKFRAME = 0x00040000;
pub const WS_TILED = 0x00000000;
pub const WS_VISIBLE = 0x10000000;
pub const WS_VSCROLL = 0x00200000;

pub const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
pub const WS_POPUPWINDOW = WS_POPUP | WS_BORDER | WS_SYSMENU;
pub const WS_TILEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;

pub const CW_USEDEFAULT = @as(c_int, @bitCast(@as(c_uint, 0x80000000)));

pub const GWLP_WNDPROC = -4;

pub const DLL_PROCESS_DETACH = 0;
pub const DLL_PROCESS_ATTACH = 1;
pub const DLL_THREAD_ATTACH = 2;
pub const DLL_THREAD_DETACH = 3;

pub const WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0;
pub const WINHTTP_ACCESS_TYPE_NO_PROXY = 1;

pub const WINHTTP_NO_PROXY_NAME = null;
pub const WINHTTP_NO_PROXY_BYPASS = null;
pub const WINHTTP_NO_REFERER = null;
pub const WINHTTP_NO_REQUEST_DATA = null;
pub const WINHTTP_NO_ADDITIONAL_HEADERS = null;
pub const WINHTTP_NO_HEADER_INDEX = null;

pub const WINHTTP_HEADER_NAME_BY_INDEX = null;

pub const WINHTTP_IGNORE_REQUEST_TOTAL_LENGTH = 0;

pub const WINHTTP_FLAG_SECURE = 0x00800000;

pub const WINHTTP_ADDREQ_FLAG_ADD = 0x20000000;
pub const WINHTTP_ADDREQ_FLAG_REPLACE = 0x80000000;

pub const WINHTTP_DEFAULT_ACCEPT_TYPES = &[_:null]?LPCWSTR{
    unicode.wtf8ToWtf16LeStringLiteral("*/*"),
};

pub const WINHTTP_QUERY_CONTENT_LENGTH = 5;
pub const WINHTTP_QUERY_STATUS_CODE = 19;
pub const WINHTTP_QUERY_FLAG_NUMBER = 0x20000000;

pub const SetStdHandleError = error{
    Unexpected,
};

pub fn SetStdHandle(nStdHandle: DWORD, hHandle: HANDLE) SetStdHandleError!void {
    if (kernel32.SetStdHandle(nStdHandle, hHandle) == FALSE) {
        return switch (windows.GetLastError()) {
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const CreateWindowExError = error{
    Unexpected,
};

pub fn CreateWindowEx(
    dwExStyle: DWORD,
    lpClassName: ?[:0]const u8,
    lpWindowName: ?[:0]const u8,
    dwStyle: DWORD,
    X: c_int,
    Y: c_int,
    nWidth: c_int,
    nHeight: c_int,
    hWndParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: ?HINSTANCE,
    lpParam: ?LPVOID,
) CreateWindowExError!HWND {
    const lpClassName_ptr = if (lpClassName) |slice| slice.ptr else null;
    const lpWindowName_ptr = if (lpWindowName) |slice| slice.ptr else null;

    if (user32.CreateWindowExA(
        dwExStyle,
        lpClassName_ptr,
        lpWindowName_ptr,
        dwStyle,
        X,
        Y,
        nWidth,
        nHeight,
        hWndParent,
        hMenu,
        hInstance,
        lpParam,
    )) |hwnd| {
        return hwnd;
    }

    return switch (windows.kernel32.GetLastError()) {
        else => |err| windows.unexpectedError(err),
    };
}

pub fn DestroyWindow(hWnd: HWND) void {
    assert(user32.DestroyWindow(hWnd) == TRUE);
}

pub const IAgileObject = extern struct {
    vtable: [*]const *const anyopaque,

    pub const UUID = &GUID.parse("{94ea2b94-e9cc-49e0-c0ff-ee64ca8f5b90}");
};

pub const IMarshal = extern struct {
    vtable: [*]const *const anyopaque,

    pub const UUID = &GUID.parse("{00000003-0000-0000-C000-000000000046}");
};

pub const IUnknown = extern struct {
    vtable: *const IUnknownVTable,

    /// __uuidof(IUnknown) = `"00000000-0000-0000-C000-000000000046"`
    pub const UUID = &GUID{
        .Data1 = 0x00000000,
        .Data2 = 0x0000,
        .Data3 = 0x0000,
        .Data4 = .{
            0xC0, 0x00,
            0x00, 0x00,
            0x00, 0x00,
            0x00, 0x46,
        },
    };

    pub const QueryInterfaceError = error{
        InterfaceNotFound,
        OutOfMemory,
        Unexpected,
    };

    pub fn QueryInterface(self: *IUnknown, riid: REFIID, ppvObject: **anyopaque) QueryInterfaceError!void {
        const hr = self.vtable.QueryInterface(self, riid, ppvObject);
        return switch (hr) {
            windows.S_OK => {},
            windows.E_OUTOFMEMORY => error.OutOfMemory,
            windows.E_NOINTERFACE => error.InterfaceNotFound,
            windows.E_POINTER => unreachable,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub inline fn AddRef(self: *IUnknown) ULONG {
        return self.vtable.AddRef(self);
    }

    pub inline fn Release(self: *IUnknown) void {
        _ = self.vtable.Release(self);
    }
};

const IUnknownVTable = extern struct {
    QueryInterface: *const fn (self: *IUnknown, riid: REFIID, ppvObject: **anyopaque) callconv(.winapi) HRESULT,
    AddRef: *const fn (self: *IUnknown) callconv(.winapi) ULONG,
    Release: *const fn (self: *IUnknown) callconv(.winapi) ULONG,
};

pub const DisableThreadLibraryCallsError = error{Unexpected};

pub fn DisableThreadLibraryCalls(hLibModule: windows.HMODULE) DisableThreadLibraryCallsError!void {
    if (kernel32.DisableThreadLibraryCalls(hLibModule) == windows.FALSE) {
        switch (windows.kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub const PostThreadMessageError = error{
    InvalidThreadId,
    MessageLimitReached,
    Unexpected,
};

pub fn PostThreadMessage(idThread: u32, Msg: UINT, wParam: WPARAM, lParam: LPARAM) PostThreadMessageError!void {
    if (user32.PostThreadMessageA(idThread, Msg, wParam, lParam) == windows.FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            .INVALID_THREAD_ID => error.InvalidThreadId,
            .NOT_ENOUGH_QUOTA => error.MessageLimitReached,
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const CreateThreadError = error{
    OutOfMemory,
    Unexpected,
};

pub fn CreateThread(
    lpThreadAttributes: ?*SECURITY_ATTRIBUTES,
    dwStackSize: SIZE_T,
    lpStartAddress: LPTHREAD_START_ROUTINE,
    lpParameter: ?LPVOID,
    dwCreationFlags: DWORD,
    lpThreadId: ?*DWORD,
) CreateThreadError!windows.HANDLE {
    return kernel32.CreateThread(lpThreadAttributes, dwStackSize, lpStartAddress, lpParameter, dwCreationFlags, lpThreadId) orelse {
        return switch (windows.kernel32.GetLastError()) {
            .OUTOFMEMORY => error.OutOfMemory,
            else => |err| windows.unexpectedError(err),
        };
    };
}

pub const SendMessageError = error{
    Unexpected,
};

pub fn SendMessage(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) SendMessageError!void {
    if (user32.SendMessageA(hWnd, Msg, wParam, lParam) == windows.FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            .PROC_NOT_FOUND => {}, // hmm
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const PostMessageError = error{
    Unexpected,
};

pub fn PostMessage(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) PostMessageError!void {
    if (user32.PostMessageA(hWnd, Msg, wParam, lParam) == windows.FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const GetWindowThreadProcessIdError = error{
    Unexpected,
};

pub fn GetWindowThreadProcessId(hWnd: HWND) GetWindowThreadProcessIdError!struct { DWORD, DWORD } {
    var pid: DWORD = 0;
    const tid = user32.GetWindowThreadProcessId(hWnd, &pid);

    if (tid > 0) {
        return .{ tid, pid };
    }

    return switch (windows.kernel32.GetLastError()) {
        else => |err| return windows.unexpectedError(err),
    };
}

pub const AllocConsoleError = error{
    AccessDenied,
    Unexpected,
};

pub fn AllocConsole() AllocConsoleError!void {
    if (kernel32.AllocConsole() == windows.FALSE) {
        switch (windows.kernel32.GetLastError()) {
            .ACCESS_DENIED => return error.AccessDenied,
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub const FreeConsoleError = error{Unexpected};

pub fn FreeConsole() FreeConsoleError!void {
    if (kernel32.FreeConsole() == windows.FALSE) {
        switch (windows.kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub inline fn FreeLibraryAndExitThread(hLibModule: windows.HMODULE, dwExitCode: u32) void {
    kernel32.FreeLibraryAndExitThread(hLibModule, dwExitCode);
}

pub inline fn GetModuleHandle(lpModuleName: ?[:0]const u8) ?windows.HMODULE {
    const lpModuleName_ptr = if (lpModuleName) |slice| slice.ptr else null;
    return kernel32.GetModuleHandleA(lpModuleName_ptr);
}

pub const GetModuleInformationError = error{Unexpected};

pub fn GetModuleInformation(hProcess: windows.HANDLE, hModule: windows.HMODULE) GetModuleInformationError!windows.MODULEINFO {
    var module_info: windows.MODULEINFO = undefined;
    if (psapi.GetModuleInformation(hProcess, hModule, &module_info, @sizeOf(windows.MODULEINFO)) == windows.FALSE) {
        switch (windows.kernel32.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
    return module_info;
}

pub const GetProcAddressError = error{
    ProcedureNotFound,
    Unexpected,
};

pub fn GetProcAddress(hModule: windows.HMODULE, lpProcName: [:0]const u8) GetProcAddressError!windows.FARPROC {
    return kernel32.GetProcAddress(hModule, lpProcName) orelse {
        switch (windows.kernel32.GetLastError()) {
            .PROC_NOT_FOUND => return error.ProcedureNotFound,
            else => |err| return windows.unexpectedError(err),
        }
    };
}

pub inline fn GetForegroundWindow() ?windows.HWND {
    return user32.GetForegroundWindow();
}

pub inline fn OutputDebugString(lpOutputString: [:0]const u8) void {
    return kernel32.OutputDebugStringA(lpOutputString.ptr);
}

pub inline fn OutputDebugStringW(lpOutputString: [:0]const u16) void {
    return kernel32.OutputDebugStringW(lpOutputString.ptr);
}

pub fn FindWindow(ClassName: ?[:0]const u8, WindowName: ?[:0]const u8) ?windows.HWND {
    const lpClassName = if (ClassName) |slice| slice.ptr else null;
    const lpWindowName = if (WindowName) |slice| slice.ptr else null;

    return user32.FindWindowA(lpClassName, lpWindowName);
}

pub const GetWindowRectError = error{Unexpected};

pub fn GetWindowRect(hWnd: windows.HWND) GetWindowRectError!windows.RECT {
    var rect: windows.RECT = undefined;
    if (user32.GetWindowRect(hWnd, &rect) == windows.FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            else => |err| windows.unexpectedError(err),
        };
    }

    return rect;
}

pub const WinHttpOpenError = error{Unexpected};

pub fn WinHttpOpen(
    pszAgentW: ?[:0]const u16,
    dwAccessType: DWORD,
    pszProxyW: ?[:0]const u16,
    pszProxyBypassW: ?[:0]const u16,
    dwFlags: DWORD,
) WinHttpOpenError!HINTERNET {
    const pszAgentW_ptr = if (pszAgentW) |slice| slice.ptr else null;
    const pszProxyW_ptr = if (pszProxyW) |slice| slice.ptr else null;
    const pszProxyBypassW_ptr = if (pszProxyBypassW) |slice| slice.ptr else null;

    if (winhttp.WinHttpOpen(pszAgentW_ptr, dwAccessType, pszProxyW_ptr, pszProxyBypassW_ptr, dwFlags)) |session| {
        return session;
    }

    return switch (windows.kernel32.GetLastError()) {
        else => |err| windows.unexpectedError(err),
    };
}

// tood: we need error checks here
pub const GetClassNameError = error{
    Unexpected,
};

pub fn GetClassNameA(hWnd: HWND, buffer: []u8) GetClassNameError![:0]const u8 {
    const len = user32.GetClassNameA(hWnd, buffer.ptr, @intCast(buffer.len));
    if (len != 0) {
        return buffer[0..@as(usize, @intCast(len)) :0];
    }

    return switch (windows.kernel32.GetLastError()) {
        else => |err| windows.unexpectedError(err),
    };
}

pub fn WinHttpCloseHandle(hInternet: HINTERNET) void {
    assert(winhttp.WinHttpCloseHandle(hInternet) == TRUE);
}

pub const WinHttpConnectError = error{Unexpected};

pub fn WinHttpConnect(
    hSession: HINTERNET,
    pswzServerName: [:0]const u16,
    nServerPort: INTERNET_PORT,
) WinHttpConnectError!HINTERNET {
    if (winhttp.WinHttpConnect(hSession, pswzServerName.ptr, nServerPort, 0)) |connection| {
        return connection;
    }

    return switch (windows.kernel32.GetLastError()) {
        else => |err| windows.unexpectedError(err),
    };
}

pub const WinHttpOpenRequestError = error{Unexpected};

pub fn WinHttpOpenRequest(
    hConnect: HINTERNET,
    pwszVerb: [:0]const u16,
    pwszObjectName: [:0]const u16,
    pwszVersion: ?[:0]const u16,
    pwszReferrer: ?[:0]const u16,
    ppwszAcceptTypes: [:null]const ?LPCWSTR,
    dwFlags: DWORD,
) WinHttpOpenRequestError!HINTERNET {
    const pwszVersion_ptr = if (pwszVersion) |slice| slice.ptr else null;
    const pwszReferrer_ptr = if (pwszReferrer) |slice| slice.ptr else null;

    if (winhttp.WinHttpOpenRequest(hConnect, pwszVerb.ptr, pwszObjectName.ptr, pwszVersion_ptr, pwszReferrer_ptr, ppwszAcceptTypes.ptr, dwFlags)) |request| {
        return request;
    }

    return switch (windows.kernel32.GetLastError()) {
        else => |err| windows.unexpectedError(err),
    };
}

pub const WinHttpSendRequestError = error{ NetworkUnreachable, Unexpected };

pub fn WinHttpSendRequest(
    hRequest: HINTERNET,
    Headers: ?[]const u16,
    Optional: ?[]const u16,
    dwTotalLength: DWORD,
    dwContext: ?*DWORD,
) WinHttpSendRequestError!void {
    const lpszHeaders = if (Headers) |slice| slice.ptr else null;
    const dwHeadersLength: DWORD = if (Headers) |slice| @intCast(slice.len) else 0;

    const lpOptional = if (Optional) |slice| slice.ptr else null;
    const dwOptionalLength: DWORD = if (Optional) |slice| @intCast(slice.len) else 0;

    if (winhttp.WinHttpSendRequest(hRequest, lpszHeaders, dwHeadersLength, lpOptional, dwOptionalLength, dwTotalLength, dwContext) == FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            @as(Win32Error, @enumFromInt(12007)) => error.NetworkUnreachable,
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const WinHttpReceiveResponseError = error{Unexpected};

pub fn WinHttpReceiveResponse(hRequest: HINTERNET) WinHttpOpenRequestError!void {
    if (winhttp.WinHttpReceiveResponse(hRequest, null) == FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const WinHttpQueryHeadersError = error{ NoSpaceLeft, HeaderNotFound, Unexpected };

pub fn WinHttpQueryHeaders(
    hRequest: HINTERNET,
    dwInfoLevel: DWORD,
    Name: ?[:0]const u16,
    lpBuffer: ?LPCVOID,
    lpdwBufferLength: LPDWORD,
    lpdwIndex: ?LPDWORD,
) WinHttpQueryHeadersError!void {
    const pwszName = if (Name) |slice| slice.ptr else null;

    if (winhttp.WinHttpQueryHeaders(hRequest, dwInfoLevel, pwszName, lpBuffer, lpdwBufferLength, lpdwIndex) == FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            .INSUFFICIENT_BUFFER => error.NoSpaceLeft,
            @as(Win32Error, @enumFromInt(12150)) => error.HeaderNotFound,
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const WinHttpReadDataError = error{Unexpected};

pub fn WinHttpReadData(hRequest: HINTERNET, Buffer: []u8) WinHttpReadDataError!u32 {
    var lpdwNumberOfBytesRead: DWORD = 0;

    if (winhttp.WinHttpReadData(hRequest, Buffer.ptr, @truncate(Buffer.len), &lpdwNumberOfBytesRead) == FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            else => |err| windows.unexpectedError(err),
        };
    }

    return lpdwNumberOfBytesRead;
}

pub const WinHttpWriteDataError = error{Unexpected};

pub fn WinHttpWriteData(hRequest: HINTERNET, Buffer: []const u8) WinHttpWriteDataError!u32 {
    var lpdwNumberOfBytesWritten: DWORD = 0;

    if (winhttp.WinHttpWriteData(hRequest, Buffer.ptr, @truncate(Buffer.len), &lpdwNumberOfBytesWritten) == FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            else => |err| windows.unexpectedError(err),
        };
    }

    return lpdwNumberOfBytesWritten;
}

pub const WinHttpAddRequestHeadersError = error{Unexpected};

pub fn WinHttpAddRequestHeaders(
    hRequest: HINTERNET,
    Headers: []const u16,
    dwModifiers: DWORD,
) WinHttpAddRequestHeadersError!void {
    if (winhttp.WinHttpAddRequestHeaders(hRequest, Headers.ptr, @intCast(Headers.len), dwModifiers) == FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const SetWindowLongPtrError = error{
    AccessDenied,
    Unexpected,
};

pub fn SetWindowLongPtr(
    hWnd: HWND,
    nIndex: c_int,
    dwNewLong: LONG_PTR,
) SetWindowLongPtrError!LONG_PTR {
    // on 32 bit call 32 bit one!
    const res = user32.SetWindowLongPtrA(hWnd, nIndex, dwNewLong);
    if (res == 0) {
        return switch (windows.kernel32.GetLastError()) {
            .ACCESS_DENIED => error.AccessDenied,
            else => |err| windows.unexpectedError(err),
        };
    }

    return res;
}

pub const SetConsoleTitleError = error{Unexpected};

pub fn SetConsoleTitle(ConsoleTitle: [:0]const u8) SetConsoleTitleError!void {
    if (kernel32.SetConsoleTitleA(ConsoleTitle.ptr) == FALSE) {
        return switch (windows.kernel32.GetLastError()) {
            else => |err| windows.unexpectedError(err),
        };
    }
}

pub const RoInitializeError = error{Unexpected};

pub fn RoInitialize(initType: RO_INIT_TYPE) RoInitializeError!void {
    const hr = combase.RoInitialize(initType);
    return switch (hr) {
        windows.S_OK => {},
        else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
    };
}

pub inline fn RoUninitialize() void {
    combase.RoUninitialize();
}

pub const RoGetActivationFactoryError = error{Unexpected};

pub fn RoGetActivationFactory(
    activatableClassId: HSTRING,
    iid: REFIID,
    factory: **anyopaque,
) RoGetActivationFactoryError!void {
    const hr = combase.RoGetActivationFactory(activatableClassId, iid, factory);
    return switch (hr) {
        windows.S_OK => {},
        else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
    };
}

pub const WindowsCreateStringError = error{
    OutOfMemory,
    Unexpected,
};

pub fn WindowsCreateString(sourceString: [:0]const u16) WindowsCreateStringError!HSTRING {
    var hstring: HSTRING = undefined;

    const hr = combase.WindowsCreateString(sourceString.ptr, @intCast(sourceString.len), &hstring);
    return switch (hr) {
        windows.S_OK => hstring,
        windows.E_OUTOFMEMORY => error.OutOfMemory,
        windows.E_POINTER => unreachable,
        windows.E_INVALIDARG => unreachable,
        else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
    };
}

pub inline fn WindowsDeleteString(string: HSTRING) void {
    assert(combase.WindowsDeleteString(string) == windows.S_OK);
}

pub const WindowsCreateStringReferenceError = error{
    OutOfMemory,
    Unexpected,
};

pub fn WindowsCreateStringReference(sourceString: [:0]const u16, hstringHeader: *HSTRING_HEADER) WindowsCreateStringReferenceError!HSTRING {
    var hstring: HSTRING = undefined;

    const hr = combase.WindowsCreateStringReference(sourceString.ptr, @intCast(sourceString.len), hstringHeader, &hstring);
    return switch (hr) {
        windows.S_OK => hstring,
        windows.E_OUTOFMEMORY => error.OutOfMemory,
        windows.E_POINTER => unreachable,
        windows.E_INVALIDARG => unreachable,
        else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
    };
}

pub fn WindowsGetStringRawBuffer(string: HSTRING) [:0]const u16 {
    var len: UINT32 = undefined;
    const source_string = combase.WindowsGetStringRawBuffer(string, &len);

    return if (source_string) |str| str[0..len :0] else std.unicode.wtf8ToWtf16LeStringLiteral("");
}

pub const CoCreateFreeThreadedMarshalerError = error{
    OutOfMemory,
    Unexpected,
};

pub fn CoCreateFreeThreadedMarshaler(
    punkOuter: ?LPUNKNOWN,
    ppunkMarshal: LPUNKNOWN,
) CoCreateFreeThreadedMarshalerError!void {
    const hr = combase.CoCreateFreeThreadedMarshaler(punkOuter, ppunkMarshal);
    return switch (hr) {
        windows.S_OK => {},
        windows.E_OUTOFMEMORY => error.OutOfMemory,
        else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
    };
}

pub inline fn eqlGuids(guid: *const GUID, comptime guids: []const *const GUID) bool {
    inline for (guids) |tmp| {
        if (mem.eql(u8, mem.asBytes(guid), mem.asBytes(tmp))) {
            return true;
        }
    }
    return false;
}

pub inline fn uuidOf(comptime T: type) *const GUID {
    comptime {
        switch (@typeInfo(T)) {
            .@"struct" => {
                if (!@hasDecl(T, "UUID")) {
                    @compileError("'" ++ @typeName(T) ++ "' has no declaration 'UUID'");
                }
                return T.UUID;
            },
            .pointer => |ptr| return signatureOf(ptr.child),
            else => @compileError("expected struct found '" ++ @typeName(T) ++ "'"),
        }
    }
}

pub inline fn uuidFromSignature(comptime signature: []const u8) *const GUID {
    comptime {
        @setEvalBranchQuota(10_000);

        const prefix = &[_]u8{ 0x11, 0xf4, 0x7a, 0xd5, 0x7b, 0x73, 0x42, 0xc0, 0xab, 0xae, 0x87, 0x8b, 0x1e, 0x16, 0xad, 0xee };
        const data = prefix ++ signature;

        var hashed: [20]u8 = undefined;
        std.crypto.hash.Sha1.hash(data, &hashed, .{});

        const data1 = mem.readInt(u32, hashed[0..4], .big);
        const data2 = mem.readInt(u16, hashed[4..6], .big);

        const data3 = (mem.readInt(u16, hashed[6..8], .big) & 0x0fff) | (5 << 12);
        const data4 = ([1]u8{(hashed[8] & 0x3f) | 0x80} ++ hashed[9..16]).*;

        return &GUID{
            .Data1 = data1,
            .Data2 = data2,
            .Data3 = data3,
            .Data4 = data4,
        };
    }
}

fn signatureOfCount(comptime T: type) usize {
    switch (@typeInfo(T)) {
        .@"struct" => {
            if (!@hasDecl(T, "SIGNATURE")) {
                @compileError("'" ++ @typeName(T) ++ "' has no declaration 'SIGNATURE'");
            }
            return T.SIGNATURE.len;
        },
        .pointer => |ptr| return signatureOfCount(ptr.child),
        else => @compileError("expected struct found '" ++ @typeName(T) ++ "'"),
    }
}

pub inline fn signatureOf(comptime T: type) *const [signatureOfCount(T):0]u8 {
    comptime {
        switch (@typeInfo(T)) {
            .@"struct" => {
                if (!@hasDecl(T, "SIGNATURE")) {
                    @compileError("'" ++ @typeName(T) ++ "' has no declaration 'SIGNATURE'");
                }
                return T.SIGNATURE;
            },
            .pointer => |ptr| return signatureOf(ptr.child),
            else => @compileError("expected struct found '" ++ @typeName(T) ++ "'"),
        }
    }
}

pub fn AsyncOperation(comptime TResult: type) type {
    return struct {
        handle: *IAsyncOperation(TResult),

        const Self = @This();

        pub inline fn Release(self: Self) void {
            self.handle.Release();
        }

        pub inline fn Close(self: Self) void {
            self.handle.Close();
        }

        pub fn get(self: Self, allocator: Allocator) !TResult {
            var async_info: *IAsyncInfo = undefined;

            try self.handle.QueryInterface(IAsyncInfo.UUID, @ptrCast(&async_info));
            defer async_info.Release();

            if (async_info.get_Status() == .Completed) {
                return self.handle.GetResults();
            }

            var reset_event: std.Thread.ResetEvent = .{};

            const Context = struct {
                reset_event: *std.Thread.ResetEvent,

                pub fn invokeFn(ctx: @This(), _: *IAsyncInfo, _: AsyncStatus) void {
                    ctx.reset_event.set();
                }
            };

            const callback: AsyncOperationCompletedHandler(TResult) = try .init(allocator, Context{ .reset_event = &reset_event }, Context.invokeFn);
            defer callback.Release();

            try self.handle.put_Completed(callback.handle);
            reset_event.wait();

            return switch (async_info.get_Status()) {
                .Started => unreachable,
                .Completed => self.handle.GetResults(),
                .Error => {
                    // if needed we could pass in TResult and TError
                    // as these Errors depends on the operation
                    const hr = async_info.get_ErrorCode();
                    return switch (hr) {
                        windows.E_OUTOFMEMORY => error.OutOfMemory,
                        else => unexpectedError(HRESULT_CODE(hr)),
                    };
                },
                .Canceled => error.Canceled,
            };
        }

        /// Same as `get` just releases all COM resources.
        pub fn getAndForget(self: Self, allocator: Allocator) !TResult {
            defer Release(self);
            defer Close(self);
            return get(self, allocator);
        }
    };
}

pub fn AsyncOperationCompletedHandler(comptime TResult: type) type {
    return struct {
        handle: *IAsyncOperationCompletedHandler(TResult),

        pub const SIGNATURE = "pinterface({fcdcf02c-e5d8-4478-915a-4d90b74b83a5};" ++ signatureOf(TResult) ++ ")";
        pub const UUID = uuidFromSignature(SIGNATURE);

        const Self = @This();

        pub inline fn Release(self: Self) void {
            self.handle.Release();
        }

        /// Expects threadsafe allocator
        pub fn init(
            allocator: Allocator,
            context: anytype,
            comptime invokeFn: fn (@TypeOf(context), asyncInfo: *IAsyncInfo, status: AsyncStatus) void,
        ) Allocator.Error!Self {
            const Context = @TypeOf(context);
            const Closure = struct {
                vtable: *const IAsyncOperationCompletedHandlerVTable = &.{
                    .QueryInterface = &QueryInterface,
                    .AddRef = &AddRef,
                    .Release = &@This().Release,
                    .Invoke = &Invoke,
                },

                allocator: Allocator,
                ref_count: std.atomic.Value(ULONG),

                context: Context,

                fn QueryInterface(ctx: *anyopaque, riid: REFIID, ppvObject: **anyopaque) callconv(.winapi) HRESULT {
                    const self: *@This() = @ptrCast(@alignCast(ctx));

                    const guids = &[_]REFIID{
                        UUID,
                        IUnknown.UUID,
                        IAgileObject.UUID,
                    };

                    if (eqlGuids(riid, guids)) {
                        _ = self.ref_count.fetchAdd(1, .monotonic);

                        ppvObject.* = ctx;
                        return windows.S_OK;
                    }

                    if (mem.eql(u8, mem.asBytes(riid), mem.asBytes(IMarshal.UUID))) {
                        @panic("marshal requested!");
                    }

                    return windows.E_NOINTERFACE;
                }

                // todo: reusize this
                pub fn AddRef(ctx: *anyopaque) callconv(.winapi) ULONG {
                    const self: *@This() = @ptrCast(@alignCast(ctx));

                    const prev = self.ref_count.fetchAdd(1, .monotonic);
                    return prev + 1;
                }

                // todo: reusize this
                fn Release(ctx: *anyopaque) callconv(.winapi) ULONG {
                    const self: *@This() = @ptrCast(@alignCast(ctx));
                    const prev = self.ref_count.fetchSub(1, .release);

                    if (prev == 1) {
                        assert(self.ref_count.load(.acquire) == 0);
                        self.allocator.destroy(self);
                    }

                    return prev - 1;
                }

                pub fn Invoke(ctx: *anyopaque, asyncInfo: *IAsyncInfo, status: AsyncStatus) callconv(.winapi) HRESULT {
                    const self: *@This() = @ptrCast(@alignCast(ctx));
                    invokeFn(self.context, asyncInfo, status);

                    return windows.S_OK;
                }
            };

            const closure = try allocator.create(Closure);
            closure.* = .{
                .allocator = allocator,
                .ref_count = .init(1),
                .context = context,
            };

            return .{
                .handle = @ptrCast(closure),
            };
        }
    };
}

pub const GlobalSystemMediaTransportControlsSessionManager = struct {
    handle: *IGlobalSystemMediaTransportControlsSessionManager,

    pub const SIGNATURE = IGlobalSystemMediaTransportControlsSessionManager.SIGNATURE;
    pub const NAME = IGlobalSystemMediaTransportControlsSessionManager.NAME;

    pub fn RequestAsync() !AsyncOperation(GlobalSystemMediaTransportControlsSessionManager) {
        var header: HSTRING_HEADER = undefined;
        const class = try WindowsCreateStringReference(unicode.wtf8ToWtf16LeStringLiteral(NAME), &header);

        var static_manager: *IGlobalSystemMediaTransportControlsSessionManagerStatics = undefined;

        try RoGetActivationFactory(
            class,
            IGlobalSystemMediaTransportControlsSessionManagerStatics.UUID,
            @ptrCast(&static_manager),
        );
        defer static_manager.Release();

        return .{
            // safe as GlobalSystemMediaTransportControlsSessionManager is just *IGlobalSystemMediaTransportControlsSessionManager
            .handle = @ptrCast(try static_manager.RequestAsync()),
        };
    }

    pub inline fn Release(self: GlobalSystemMediaTransportControlsSessionManager) void {
        self.handle.Release();
    }

    pub fn GetCurrentSession(self: GlobalSystemMediaTransportControlsSessionManager) !?GlobalSystemMediaTransportControlsSession {
        const session = try self.handle.GetCurrentSession();
        return if (session) |handle| .{ .handle = handle } else null;
    }

    pub fn CurrentSessionChanged(
        self: GlobalSystemMediaTransportControlsSessionManager,
        allocator: Allocator,
        context: anytype,
        comptime invokeFn: fn (@TypeOf(context), session: GlobalSystemMediaTransportControlsSessionManager) anyerror!void,
    ) !i64 {
        const Handler = *TypedEventHandler(*IGlobalSystemMediaTransportControlsSessionManager, *ICurrentSessionChangedEventArgs);
        const WrappedContext = struct {
            original: @TypeOf(context),

            fn wrappedInvokeFn(ctx: @This(), sender: *IGlobalSystemMediaTransportControlsSessionManager, _: *ICurrentSessionChangedEventArgs) void {
                invokeFn(ctx.original, .{ .handle = sender }) catch |err| {
                    std.debug.print("error: {s}\n", .{@errorName(err)});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                    }
                };
            }
        };

        const handler: Handler = try .init(allocator, WrappedContext{ .original = context }, WrappedContext.wrappedInvokeFn);
        defer handler.Release();

        return (try self.handle.add_CurrentSessionChanged(handler)).value;
    }

    pub inline fn RemoveCurrentSessionChanged(self: GlobalSystemMediaTransportControlsSessionManager, token: i64) !void {
        return self.handle.remove_CurrentSessionChanged(.{ .value = token });
    }
};

pub const GlobalSystemMediaTransportControlsSessionPlaybackInfo = struct {
    handle: *IGlobalSystemMediaTransportControlsSessionPlaybackInfo,

    pub inline fn Release(self: GlobalSystemMediaTransportControlsSessionPlaybackInfo) void {
        self.handle.Release();
    }

    pub inline fn PlaybackStatus(self: GlobalSystemMediaTransportControlsSessionPlaybackInfo) MediaPlaybackStatus {
        return self.handle.get_PlaybackStatus();
    }
};

pub const GlobalSystemMediaTransportControlsSessionTimelineProperties = struct {
    handle: *IGlobalSystemMediaTransportControlsSessionTimelineProperties,

    pub inline fn Release(self: GlobalSystemMediaTransportControlsSessionTimelineProperties) void {
        self.handle.Release();
    }

    pub inline fn StartTime(self: GlobalSystemMediaTransportControlsSessionTimelineProperties) i64 {
        return self.handle.get_StartTime().Duration;
    }

    /// A time period expressed in 100-nanosecond units.
    pub inline fn EndTime(self: GlobalSystemMediaTransportControlsSessionTimelineProperties) i64 {
        return self.handle.get_EndTime().Duration;
    }

    /// A time period expressed in 100-nanosecond units.
    pub inline fn Position(self: GlobalSystemMediaTransportControlsSessionTimelineProperties) i64 {
        return self.handle.get_Position().Duration;
    }
};

pub const GlobalSystemMediaTransportControlsSession = struct {
    handle: *IGlobalSystemMediaTransportControlsSession,

    pub inline fn Release(self: GlobalSystemMediaTransportControlsSession) void {
        self.handle.Release();
    }

    pub fn SourceAppUserModelId(self: GlobalSystemMediaTransportControlsSession) ![:0]const u16 {
        const hstring = try self.handle.get_SourceAppUserModelId();
        return WindowsGetStringRawBuffer(hstring);
    }

    pub fn TryGetMediaPropertiesAsync(self: GlobalSystemMediaTransportControlsSession) !AsyncOperation(GlobalSystemMediaTransportControlsSessionMediaProperties) {
        return .{
            .handle = @ptrCast(try self.handle.TryGetMediaPropertiesAsync()),
        };
    }

    pub fn GetTimelineProperties(self: GlobalSystemMediaTransportControlsSession) !GlobalSystemMediaTransportControlsSessionTimelineProperties {
        return .{ .handle = try self.handle.GetTimelineProperties() };
    }

    pub fn GetPlaybackInfo(self: GlobalSystemMediaTransportControlsSession) !GlobalSystemMediaTransportControlsSessionPlaybackInfo {
        return .{ .handle = try self.handle.GetPlaybackInfo() };
    }

    pub fn PlaybackInfoChanged(
        self: GlobalSystemMediaTransportControlsSession,
        allocator: Allocator,
        context: anytype,
        comptime invokeFn: fn (@TypeOf(context), session: GlobalSystemMediaTransportControlsSession) anyerror!void,
    ) !i64 {
        const Handler = *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *IPlaybackInfoChangedEventArgs);
        const WrappedContext = struct {
            original: @TypeOf(context),

            fn wrappedInvokeFn(ctx: @This(), sender: *IGlobalSystemMediaTransportControlsSession, _: *IPlaybackInfoChangedEventArgs) void {
                invokeFn(ctx.original, .{ .handle = sender }) catch |err| {
                    std.debug.print("error: {s}\n", .{@errorName(err)});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                    }
                };
            }
        };

        const handler: Handler = try .init(allocator, WrappedContext{ .original = context }, WrappedContext.wrappedInvokeFn);
        defer handler.Release();

        return (try self.handle.add_PlaybackInfoChanged(handler)).value;
    }

    pub fn TimelinePropertiesChanged(
        self: GlobalSystemMediaTransportControlsSession,
        allocator: Allocator,
        context: anytype,
        comptime invokeFn: fn (@TypeOf(context), session: GlobalSystemMediaTransportControlsSession) anyerror!void,
    ) !i64 {
        const Handler = *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *ITimelinePropertiesChangedEventArgs);
        const WrappedContext = struct {
            original: @TypeOf(context),

            fn wrappedInvokeFn(ctx: @This(), sender: *IGlobalSystemMediaTransportControlsSession, _: *ITimelinePropertiesChangedEventArgs) void {
                invokeFn(ctx.original, .{ .handle = sender }) catch |err| {
                    std.debug.print("error: {s}\n", .{@errorName(err)});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                    }
                };
            }
        };

        const handler: Handler = try .init(allocator, WrappedContext{ .original = context }, WrappedContext.wrappedInvokeFn);
        defer handler.Release();

        return (try self.handle.add_TimelinePropertiesChanged(handler)).value;
    }

    pub inline fn RemoveTimelinePropertiesChanged(self: GlobalSystemMediaTransportControlsSession, token: i64) !void {
        return self.handle.remove_TimelinePropertiesChanged(.{ .value = token });
    }

    pub fn MediaPropertiesChanged(
        self: GlobalSystemMediaTransportControlsSession,
        allocator: Allocator,
        context: anytype,
        comptime invokeFn: fn (@TypeOf(context), session: GlobalSystemMediaTransportControlsSession) anyerror!void,
    ) !i64 {
        const Handler = *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *IMediaPropertiesChangedEventArgs);
        const WrappedContext = struct {
            original: @TypeOf(context),

            fn wrappedInvokeFn(ctx: @This(), sender: *IGlobalSystemMediaTransportControlsSession, _: *IMediaPropertiesChangedEventArgs) void {
                invokeFn(ctx.original, .{ .handle = sender }) catch |err| {
                    std.debug.print("error: {s}\n", .{@errorName(err)});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                    }
                };
            }
        };

        const handler: Handler = try .init(allocator, WrappedContext{ .original = context }, WrappedContext.wrappedInvokeFn);
        defer handler.Release();

        return (try self.handle.add_MediaPropertiesChanged(handler)).value;
    }

    pub inline fn RemoveMediaPropertiesChanged(self: GlobalSystemMediaTransportControlsSession, token: i64) !void {
        return self.handle.remove_MediaPropertiesChanged(.{ .value = token });
    }
};

pub const PixelDataProvider = struct {
    handle: *IPixelDataProvider,

    pub const SIGNATURE = IPixelDataProvider.SIGNATURE;

    pub inline fn Release(self: PixelDataProvider) void {
        return self.handle.Release();
    }

    pub fn DetachPixelData(self: PixelDataProvider) []const u8 {
        var ptr: [*]const u8 = undefined;
        var len: u32 = undefined;

        self.handle.DetachPixelData(&len, &ptr);
        return ptr[0..len];
    }
};

pub const GlobalSystemMediaTransportControlsSessionMediaProperties = struct {
    handle: *IGlobalSystemMediaTransportControlsSessionMediaProperties,

    pub const SIGNATURE = IGlobalSystemMediaTransportControlsSessionMediaProperties.SIGNATURE;

    pub inline fn Release(self: GlobalSystemMediaTransportControlsSessionMediaProperties) void {
        self.handle.Release();
    }

    pub inline fn Title(self: GlobalSystemMediaTransportControlsSessionMediaProperties) [:0]const u16 {
        return WindowsGetStringRawBuffer(self.handle.get_Title());
    }

    pub inline fn Artist(self: GlobalSystemMediaTransportControlsSessionMediaProperties) [:0]const u16 {
        return WindowsGetStringRawBuffer(self.handle.get_Artist());
    }

    pub inline fn Thumbnail(self: GlobalSystemMediaTransportControlsSessionMediaProperties) !?RandomAccessStreamReference {
        return if (try self.handle.get_Thumbnail()) |thumbnail| return .{ .handle = thumbnail } else null;
    }
};

pub const RandomAccessStreamReference = struct {
    handle: *IRandomAccessStreamReference,

    pub inline fn Release(self: RandomAccessStreamReference) void {
        self.handle.Release();
    }

    pub inline fn OpenReadAsync(self: RandomAccessStreamReference) !AsyncOperation(*IRandomAccessStreamWithContentType) {
        return .{ .handle = try self.handle.OpenReadAsync() };
    }
};

pub const BitmapDecoder = struct {
    handle: *IBitmapDecoder,

    const NAME = IBitmapDecoder.NAME;
    const SIGNATURE = IBitmapDecoder.SIGNATURE;

    pub fn CreateAsync(stream: *IRandomAccessStream) !AsyncOperation(BitmapDecoder) {
        var header: HSTRING_HEADER = undefined;
        const class = try WindowsCreateStringReference(unicode.wtf8ToWtf16LeStringLiteral(NAME), &header);

        var static_bitmap_decoder: *IBitmapDecoderStatics = undefined;

        try RoGetActivationFactory(
            class,
            IBitmapDecoderStatics.UUID,
            @ptrCast(&static_bitmap_decoder),
        );
        defer static_bitmap_decoder.Release();

        return .{
            .handle = @ptrCast(try static_bitmap_decoder.CreateAsync(stream)),
        };
    }

    pub inline fn Release(self: BitmapDecoder) void {
        self.handle.Release();
    }

    pub inline fn GetFrameAsync(self: BitmapDecoder, frameIndex: UINT32) !AsyncOperation(BitmapFrame) {
        return .{
            .handle = @ptrCast(try self.handle.GetFrameAsync(frameIndex)),
        };
    }
};

pub const IRandomAccessStream = extern struct {
    vtable: [*]const *const anyopaque,
};

pub const BitmapFrame = struct {
    handle: *IBitmapFrame,

    pub const SIGNATURE = IBitmapFrame.SIGNATURE;

    pub inline fn Release(self: BitmapFrame) void {
        self.handle.Release();
    }

    pub inline fn PixelWidth(self: BitmapFrame) UINT32 {
        return self.handle.get_PixelWidth();
    }

    pub inline fn PixelHeight(self: BitmapFrame) UINT32 {
        return self.handle.get_PixelHeight();
    }

    pub inline fn GetPixelDataTransformedAsync(
        self: BitmapFrame,
        pixelFormat: BitmapPixelFormat,
        alphaMode: BitmapAlphaMode,
        transform: *IBitmapTransform,
        exifOrientationMode: ExifOrientationMode,
        colorManagementMode: ColorManagementMode,
    ) !AsyncOperation(PixelDataProvider) {
        return .{ .handle = @ptrCast(try self.handle.GetPixelDataTransformedAsync(
            pixelFormat,
            alphaMode,
            transform,
            exifOrientationMode,
            colorManagementMode,
        )) };
    }
};

pub const IActivationFactory = extern struct {
    vtable: [*]const *const anyopaque,

    pub const UUID = &GUID.parse("{00000035-0000-0000-c000-000000000046}");

    pub inline fn Release(self: *IActivationFactory) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub const ActivateInstanceError = error{Unexpected};

    pub fn ActivateInstance(self: *IActivationFactory, instance: **anyopaque) ActivateInstanceError!void {
        const FnType = fn (*IActivationFactory, **anyopaque) callconv(.winapi) HRESULT;
        const activate_instance: *const FnType = @ptrCast(self.vtable[6]);

        const hr = activate_instance(self, instance);
        return switch (hr) {
            windows.S_OK => {},
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }
};
