const std = @import("std");
const windows = @import("../windows.zig");

pub const d3d11 = @import("d3d11.zig");
pub const DXGI_ERROR = @import("dxgi_err.zig").DXGI_ERROR;

const INT = windows.INT;
const S_OK = windows.S_OK;
const HWND = windows.HWND;
const BOOL = windows.BOOL;
const UINT = windows.UINT;
const ULONG = windows.ULONG;
const HRESULT = windows.HRESULT;
const REFIID = windows.REFIID;
const REFGUID = windows.REFGUID;
const IUnknown = windows.IUnknown;
const WINBOOL = windows.WINBOOL;
const LARGE_INTEGER = windows.LARGE_INTEGER;

pub const IDXGIAdapter = *opaque {};
pub const IDXGIOutput = *opaque {};

pub const DXGI_FORMAT = INT;
pub const DXGI_FORMAT_R32G32B32_FLOAT = 6;
pub const DXGI_FORMAT_R32G32_FLOAT = 16;
pub const DXGI_FORMAT_R8G8B8A8_UNORM = 28;
pub const DXGI_FORMAT_R32_UINT = 42;
pub const DXGI_FORMAT_R16_UINT = 57;
pub const DXGI_FORMAT_R8_UNORM = 61;
pub const DXGI_FORMAT_R8_UINT = 62;

pub const DXGI_SWAP_EFFECT = INT;
pub const DXGI_SWAP_EFFECT_DISCARD = 0;

pub const DXGI_USAGE = INT;
pub const DXGI_USAGE_RENDER_TARGET_OUTPUT = 32;

pub const DXGI_MODE_SCANLINE_ORDER = INT;
pub const DXGI_MODE_SCALING = INT;

pub const DXGI_RATIONAL = extern struct {
    Numerator: UINT,
    Denominator: UINT,
};

pub const DXGI_FRAME_STATISTICS = extern struct {
    PresentCount: UINT,
    PresentRefreshCount: UINT,
    SyncRefreshCount: UINT,
    SyncQPCTime: LARGE_INTEGER,
    SyncGPUTime: LARGE_INTEGER,
};

pub const DXGI_MODE_DESC = extern struct {
    Width: UINT,
    Height: UINT,
    RefreshRate: DXGI_RATIONAL,
    Format: DXGI_FORMAT,
    ScanlineOrdering: DXGI_MODE_SCANLINE_ORDER,
    Scaling: DXGI_MODE_SCALING,
};

pub const DXGI_SAMPLE_DESC = extern struct {
    Count: UINT,
    Quality: UINT,
};

pub const DXGI_SWAP_CHAIN_DESC = extern struct {
    BufferDesc: DXGI_MODE_DESC,
    SampleDesc: DXGI_SAMPLE_DESC,
    BufferUsage: DXGI_USAGE,
    BufferCount: UINT,
    OutputWindow: HWND,
    Windowed: BOOL,
    SwapEffect: DXGI_SWAP_EFFECT,
    Flags: UINT,
};

pub const IDXGISwapChain = extern struct {
    vtable: *const IDXGISwapChainVTable,

    pub inline fn AddRef(self: *IDXGISwapChain) void {
        _ = self.vtable.AddRef(self);
    }

    pub inline fn Release(self: *IDXGISwapChain) void {
        _ = self.vtable.Release(self);
    }

    pub const GetDeviceError = error{Unexpected};

    pub fn GetDevice(self: *IDXGISwapChain, comptime T: type) GetDeviceError!*T {
        var device: *T = undefined;
        const result = self.vtable.GetDevice(self, T.UUID, @ptrCast(&device));

        return switch (DXGI_ERROR_CODE(result)) {
            .SUCCESS => device,
            else => |err| unexpectedError(err),
        };
    }

    pub const GetDescError = error{Unexpected};

    pub fn GetDesc(self: *IDXGISwapChain) GetDescError!DXGI_SWAP_CHAIN_DESC {
        var pDesc: DXGI_SWAP_CHAIN_DESC = undefined;

        const hr = self.vtable.getDesc(self, &pDesc);
        return switch (DXGI_ERROR_CODE(hr)) {
            .SUCCESS => pDesc,
            else => |err| unexpectedError(err),
        };
    }


    pub const GetBufferError = error{Unexpected};

    pub fn GetBuffer(
        self: *IDXGISwapChain,
        Buffer: UINT,
        comptime T: type,
    ) GetBufferError!*T {
        var surface: *T = undefined;
        const hr = self.vtable.GetBuffer(self, Buffer, T.UUID, @ptrCast(&surface));

        return switch (DXGI_ERROR_CODE(hr)) {
            .SUCCESS => surface,
            else => |err| unexpectedError(err),
        };
    }
};

const IDXGISwapChainVTable = extern struct {
    QueryInterface: *const fn (*IDXGISwapChain, riid: REFIID, ppvObject: **anyopaque) callconv(.winapi) HRESULT,
    AddRef: *const fn (*IDXGISwapChain) callconv(.winapi) ULONG,
    Release: *const fn (*IDXGISwapChain) callconv(.winapi) ULONG,
    SetPrivateData: *const fn (*IDXGISwapChain, guid: REFGUID, data_size: UINT, data: *const anyopaque) callconv(.winapi) HRESULT,
    SetPrivateDataInterface: *const fn (*IDXGISwapChain, guid: REFGUID, objecta: *const IUnknown) callconv(.winapi) HRESULT,
    GetPrivateData: *const fn (*IDXGISwapChain, guid: REFGUID, data_size: UINT, data: *anyopaque) callconv(.winapi) HRESULT,
    GetParent: *const fn (*IDXGISwapChain, riid: REFIID, parent: **anyopaque) callconv(.winapi) HRESULT,
    GetDevice: *const fn (*IDXGISwapChain, riid: REFIID, device: **anyopaque) callconv(.winapi) HRESULT,
    Present: *const fn (*IDXGISwapChain, sync_interval: UINT, flags: UINT) callconv(.winapi) HRESULT,
    GetBuffer: *const fn (*IDXGISwapChain, buffer_idx: UINT, riid: REFIID, surface: **anyopaque) callconv(.winapi) HRESULT,
    SetFullscreenState: *const fn (*IDXGISwapChain, fullscreen: WINBOOL, target: *IDXGIOutput) callconv(.winapi) HRESULT,
    GetFullscreenState: *const fn (*IDXGISwapChain, fullscreen: *WINBOOL, target: **IDXGIOutput) callconv(.winapi) HRESULT,
    GetDesc: *const fn (*IDXGISwapChain, desc: *DXGI_SWAP_CHAIN_DESC) callconv(.winapi) HRESULT,
    ResizeBuffers: *const fn (*IDXGISwapChain, buffer_count: UINT, width: UINT, height: UINT, format: DXGI_FORMAT, flags: UINT) callconv(.winapi) HRESULT,
    ResizeTarget: *const fn (*IDXGISwapChain, target_mode_desc: *const DXGI_MODE_DESC) callconv(.winapi) HRESULT,
    GetContainingOutput: *const fn (*IDXGISwapChain, output: **IDXGIOutput) callconv(.winapi) HRESULT,
    GetFrameStatistics: *const fn (*IDXGISwapChain, stats: *DXGI_FRAME_STATISTICS) callconv(.winapi) HRESULT,
    GetLastPresentCount: *const fn (*IDXGISwapChain, last_present_count: *UINT) callconv(.winapi) HRESULT,
};

pub inline fn DXGI_ERROR_CODE(hr: HRESULT) DXGI_ERROR {
    return @enumFromInt(hr);
}

pub const UnexpectedError = error{
    Unexpected,
};

pub fn unexpectedError(err: DXGI_ERROR) UnexpectedError {
    @branchHint(.cold);
    if (std.options.unexpected_error_tracing) {
        std.debug.print("error.Unexpected DXGI_ERROR=0x{x} ({s})\n", .{
            @intFromEnum(err),
            std.enums.tagName(DXGI_ERROR, err) orelse "<unnamed>",
        });
        std.debug.dumpCurrentStackTrace(.{ .first_address = @returnAddress() });
    }
    return error.Unexpected;
}
