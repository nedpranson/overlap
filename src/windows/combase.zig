const windows = @import("../windows.zig");

const UINT32 = windows.UINT32;
const HRESULT = windows.HRESULT;
const REFIID = windows.REFIID;
const PCNZWCH = windows.PCNZWCH;
const HSTRING = windows.HSTRING;
const PCWSTR = windows.PCWSTR;
const LPUNKNOWN = windows.LPUNKNOWN;
const RO_INIT_TYPE = windows.RO_INIT_TYPE;
const HSTRING_HEADER = windows.HSTRING_HEADER;

pub extern "api-ms-win-core-winrt-l1-1-0" fn RoInitialize(initType: RO_INIT_TYPE) callconv(.winapi) HRESULT;

pub extern "api-ms-win-core-winrt-l1-1-0" fn RoUninitialize() callconv(.winapi) void;

pub extern "api-ms-win-core-winrt-l1-1-0" fn RoGetActivationFactory(
    activatableClassId: HSTRING,
    iid: REFIID,
    factory: **anyopaque,
) callconv(.winapi) HRESULT;

pub extern "api-ms-win-core-winrt-string-l1-1-0" fn WindowsCreateString(
    sourceString: PCNZWCH,
    length: UINT32,
    string: *HSTRING,
) callconv(.winapi) HRESULT;

pub extern "api-ms-win-core-winrt-string-l1-1-0" fn WindowsDeleteString(
    string: HSTRING,
) callconv(.winapi) HRESULT;

pub extern "api-ms-win-core-winrt-string-l1-1-0" fn WindowsCreateStringReference(
    sourceString: PCNZWCH,
    length: UINT32,
    hstringHeader: *HSTRING_HEADER,
    string: *HSTRING,
) callconv(.winapi) HRESULT;

pub extern "api-ms-win-core-winrt-string-l1-1-0" fn WindowsGetStringRawBuffer(
    string: HSTRING,
    length: *UINT32,
) callconv(.winapi) ?PCWSTR;
