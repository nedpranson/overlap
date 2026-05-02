const windows = @import("../windows.zig");

const d3dcommon = windows.d3dcommon;
const d3d11 = windows.d3d11;

const UINT = windows.UINT;
const SIZE_T = windows.SIZE_T;
const LPCSTR = windows.LPCSTR;
const HRESULT = windows.HRESULT;
const LPCVOID = windows.LPCVOID;
const ID3DBlob = d3dcommon.ID3DBlob;
const D3D11_ERROR = d3d11.D3D11_ERROR;

pub const ID3DInclude = *opaque {};

pub const D3D_SHADER_MACRO = extern struct {
    Name: LPCSTR,
    Definition: LPCSTR,
};

pub extern "d3dcompiler_47" fn D3DCompile(
    pSrcData: LPCVOID,
    SrcDataSize: SIZE_T,
    pSourceName: ?LPCSTR,
    pDefines: ?*D3D_SHADER_MACRO,
    pInclude: ?*ID3DInclude,
    pEntrypoint: LPCSTR,
    pTarget: LPCSTR,
    Flags1: UINT,
    Flags2: UINT,
    ppCode: **ID3DBlob,
    ppErrorMsgs: ?**ID3DBlob,
) callconv(.winapi) D3D11_ERROR;
