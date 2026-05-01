const windows = @import("../windows.zig");
const HRESULT = windows.HRESULT;

pub const D3D11_ERROR = enum(HRESULT) {
    // No error occurred.
    OK = 0,
    // Alternate success value, indicating a successful but nonstandard completion (the precise meaning depends on context).
    FALSE = 1,
    // The method call isn't implemented with the passed parameter combination.
    NOTIMPL = @as(c_long, @bitCast(@as(c_ulong, 0x80004001))),
    // Direct3D could not allocate sufficient memory to complete the call.
    OUTOFMEMORY = @as(c_long, @bitCast(@as(c_ulong, 0x8007000E))),
    // An invalid parameter was passed to the returning function.
    INVALIDARG = @as(c_long, @bitCast(@as(c_ulong, 0x80070057))),
    // Attempted to create a device with the debug layer enabled and the layer is not installed.
    FAIL = @as(c_long, @bitCast(@as(c_ulong, 0x80004005))),
    // The previous blit operation that is transferring information to or from this surface is incomplete.
    // D3DERR_WASSTILLDRAWING (replaced with DXGI_ERROR_WAS_STILL_DRAWING
    WAS_STILL_DRAWING = @as(c_long, @bitCast(@as(c_ulong, 0x887A000A))),
    // The method call is invalid. For example, a method's parameter may not be a valid pointer.
    // D3DERR_INVALIDCALL (replaced with DXGI_ERROR_INVALID_CALL)
    INVALID_CALL = @as(c_long, @bitCast(@as(c_ulong, 0x887A0001))),
    // The first call to ID3D11DeviceContext::Map after either ID3D11Device::CreateDeferredContext or ID3D11DeviceContext::FinishCommandList per Resource was not D3D11_MAP_WRITE_DISCARD.
    DEFERRED_CONTEXT_MAP_WITHOUT_INITIAL_DISCARD = @as(c_long, @bitCast(@as(c_ulong, 0x887C0004))),
    // There are too many unique instances of a particular type of view object.
    TOO_MANY_UNIQUE_VIEW_OBJECTS = @as(c_long, @bitCast(@as(c_ulong, 0x887C0003))),
    // There are too many unique instances of a particular type of state object.
    TOO_MANY_UNIQUE_STATE_OBJECTS = @as(c_long, @bitCast(@as(c_ulong, 0x887C0001))),
    // The file was not found.
    ERROR_FILE_NOT_FOUND = @as(c_long, @bitCast(@as(c_ulong, 0x887C0002))),

    _,
};
