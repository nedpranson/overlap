const std = @import("std");
const windows = @import("../windows.zig");
const dxgi = @import("dxgi.zig");
const d3dcommon = @import("d3dcommon.zig");
const assert = std.debug.assert;

pub const D3D11_ERROR = @import("d3d11_err.zig").D3D11_ERROR;

const INT = windows.INT;
const GUID = windows.GUID;
const BOOL = windows.BOOL;
const UINT = windows.UINT;
const UINT8 = u8;
const ULONG = windows.ULONG;
const FLOAT = windows.FLOAT;
const SIZE_T = windows.SIZE_T;
const LPCSTR = windows.LPCSTR;
const LPCVOID = windows.LPCVOID;
const HRESULT = windows.HRESULT;
const HMODULE = windows.HMODULE;
const IUnknown = windows.IUnknown;
const DXGI_FORMAT = dxgi.DXGI_FORMAT;
const IDXGIAdapter = dxgi.IDXGIAdapter;
const IDXGISwapChain = dxgi.IDXGISwapChain;
const D3D_DRIVER_TYPE = d3dcommon.D3D_DRIVER_TYPE;
const DXGI_SWAP_CHAIN_DESC = dxgi.DXGI_SWAP_CHAIN_DESC;
const D3D_FEATURE_LEVEL = d3dcommon.D3D_FEATURE_LEVEL;

pub const D3D11_SDK_VERSION = 7;
pub const D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE = 16;
pub const D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT = 8;

pub const D3D11_PRIMITIVE_TOPOLOGY = d3dcommon.D3D_PRIMITIVE_TOPOLOGY;
pub const D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST = d3dcommon.D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;

pub const D3D11_MAP = INT;
pub const D3D11_MAP_READ = 1;
pub const D3D11_MAP_WRITE = 2;
pub const D3D11_MAP_READ_WRITE = 3;
pub const D3D11_MAP_WRITE_DISCARD = 4;
pub const D3D11_MAP_WRITE_NO_OVERWRITE = 5;

pub const D3D11_CPU_ACCESS_WRITE = 0x10000;
pub const D3D11_CPU_ACCESS_READ = 0x20000;

pub const D3D11_BIND_VERTEX_BUFFER = 1;
pub const D3D11_BIND_INDEX_BUFFER = 2;
pub const D3D11_BIND_CONSTANT_BUFFER = 4;
pub const D3D11_BIND_SHADER_RESOURCE = 8;

pub const D3D11_INPUT_CLASSIFICATION = INT;
pub const D3D11_INPUT_PER_VERTEX_DATA = 0;
pub const D3D11_INPUT_PER_INSTANCE_DATA = 1;

pub const D3D11_USAGE = INT;
pub const D3D11_USAGE_DEFAULT = 0;
pub const D3D11_USAGE_IMMUTABLE = 1;
pub const D3D11_USAGE_DYNAMIC = 2;
pub const D3D11_USAGE_STAGING = 3;

pub const D3D11_BLEND = INT;
pub const D3D11_BLEND_ZERO = 1;
pub const D3D11_BLEND_ONE = 2;
pub const D3D11_BLEND_SRC_COLOR = 3;
pub const D3D11_BLEND_INV_SRC_COLOR = 4;
pub const D3D11_BLEND_SRC_ALPHA = 5;
pub const D3D11_BLEND_INV_SRC_ALPHA = 6;
pub const D3D11_BLEND_DEST_ALPHA = 7;
pub const D3D11_BLEND_INV_DEST_ALPHA = 8;
pub const D3D11_BLEND_DEST_COLOR = 9;
pub const D3D11_BLEND_INV_DEST_COLOR = 10;
pub const D3D11_BLEND_SRC_ALPHA_SAT = 11;
pub const D3D11_BLEND_BLEND_FACTOR = 14;
pub const D3D11_BLEND_INV_BLEND_FACTOR = 15;
pub const D3D11_BLEND_SRC1_COLOR = 16;
pub const D3D11_BLEND_INV_SRC1_COLOR = 17;
pub const D3D11_BLEND_SRC1_ALPHA = 18;
pub const D3D11_BLEND_INV_SRC1_ALPHA = 1;

pub const D3D11_BLEND_OP = INT;
pub const D3D11_BLEND_OP_ADD = 1;
pub const D3D11_BLEND_OP_SUBTRACT = 2;
pub const D3D11_BLEND_OP_REV_SUBTRACT = 3;
pub const D3D11_BLEND_OP_MIN = 4;
pub const D3D11_BLEND_OP_MAX = 5;

pub const D3D11_FILTER = INT;
pub const D3D11_FILTER_MIN_MAG_MIP_LINEAR = 0x15;
pub const D3D11_FILTER_ANISOTROPIC = 0x55;

pub const D3D11_TEXTURE_ADDRESS_MODE = INT;
pub const D3D11_TEXTURE_ADDRESS_CLAMP = 3;

pub const D3D11_COMPARISON_FUNC = INT;
pub const D3D11_COMPARISON_ALWAYS = 8;

pub const D3D11_COLOR_WRITE_ENABLE_ALL = 15;

pub const ID3D11ClassLinkage = IUnknown;
pub const ID3D11ClassInstance = IUnknown;
pub const ID3D11Resource = IUnknown;
pub const ID3D11DepthStencilView = IUnknown;
pub const ID3D11RasterizerState = IUnknown;
pub const ID3D11BlendState = IUnknown;
pub const ID3D11DepthStencilState = IUnknown;
pub const ID3D11ShaderResourceView = IUnknown;
pub const ID3D11SamplerState = IUnknown;
pub const ID3D11GeometryShader = IUnknown;
pub const ID3D11RenderTargetView = IUnknown;
pub const ID3D11Buffer = IUnknown;
pub const ID3D11InputLayout = IUnknown;
pub const ID3D11VertexShader = IUnknown;
pub const ID3D11PixelShader = IUnknown;

pub const D3D11_RENDER_TARGET_VIEW_DESC = opaque {};
pub const D3D11_SHADER_RESOURCE_VIEW_DESC = opaque {};
pub const D3D11_RECT = windows.RECT;

pub const D3D11_SAMPLER_DESC = extern struct {
    Filter: D3D11_FILTER,
    AddressU: D3D11_TEXTURE_ADDRESS_MODE,
    AddressV: D3D11_TEXTURE_ADDRESS_MODE,
    AddressW: D3D11_TEXTURE_ADDRESS_MODE,
    MipLODBias: FLOAT,
    MaxAnisotropy: UINT,
    ComparisonFunc: D3D11_COMPARISON_FUNC,
    BorderColor: *const [4]FLOAT,
    MinLOD: FLOAT,
    MaxLOD: FLOAT,
};

pub const DXGI_SAMPLE_DESC = extern struct {
    Count: UINT,
    Quality: UINT,
};

pub const D3D11_TEXTURE2D_DESC = extern struct {
    Width: UINT,
    Height: UINT,
    MipLevels: UINT,
    ArraySize: UINT,
    Format: DXGI_FORMAT,
    SampleDesc: DXGI_SAMPLE_DESC,
    Usage: D3D11_USAGE,
    BindFlags: UINT,
    CPUAccessFlags: UINT,
    MiscFlags: UINT,
};

pub const D3D11_RENDER_TARGET_BLEND_DESC = extern struct {
    BlendEnable: BOOL,
    SrcBlend: D3D11_BLEND,
    DestBlend: D3D11_BLEND,
    BlendOp: D3D11_BLEND_OP,
    SrcBlendAlpha: D3D11_BLEND,
    DestBlendAlpha: D3D11_BLEND,
    BlendOpAlpha: D3D11_BLEND_OP,
    RenderTargetWriteMask: UINT8,
};

pub const D3D11_BLEND_DESC = extern struct {
    AlphaToCoverageEnable: BOOL,
    IndependentBlendEnable: BOOL,
    RenderTarget: [8]D3D11_RENDER_TARGET_BLEND_DESC,
};

pub const D3D11_MAPPED_SUBRESOURCE = extern struct {
    pData: [*]u8,
    RowPitch: UINT,
    DepthPitch: UINT,

    pub inline fn write(
        self: D3D11_MAPPED_SUBRESOURCE,
        comptime T: type,
        slice: []const T,
        pitch: u32,
    ) void {
        const ptr: [*]T = @ptrCast(@alignCast(self.pData));
        if (self.RowPitch != pitch) {
            @branchHint(.unlikely);

            const rows = @divExact(slice.len * @sizeOf(T), pitch);
            for (0..rows) |y| {
                const src_idx = y * pitch;
                const dst_idx = y * self.RowPitch;

                @memcpy(ptr[dst_idx .. dst_idx + pitch], slice[src_idx .. src_idx + pitch]);
            }

            return;
        }
        @memcpy(ptr[0..slice.len], slice);
    }
};

pub const D3D11_VIEWPORT = extern struct {
    TopLeftX: FLOAT,
    TopLeftY: FLOAT,
    Width: FLOAT,
    Height: FLOAT,
    MinDepth: FLOAT,
    MaxDepth: FLOAT,
};

pub const D3D11_INPUT_ELEMENT_DESC = extern struct {
    SemanticName: LPCSTR,
    SemanticIndex: UINT,
    Format: DXGI_FORMAT,
    InputSlot: UINT,
    AlignedByteOffset: UINT,
    InputSlotClass: D3D11_INPUT_CLASSIFICATION,
    InstanceDataStepRate: UINT,
};

pub const D3D11_BUFFER_DESC = extern struct {
    ByteWidth: UINT,
    Usage: D3D11_USAGE,
    BindFlags: UINT,
    CPUAccessFlags: UINT,
    MiscFlags: UINT,
    StructureByteStride: UINT,
};

pub const D3D11_SUBRESOURCE_DATA = extern struct {
    pSysMem: LPCVOID,
    SysMemPitch: UINT,
    SysMemSlicePitch: UINT,
};

pub const ID3D11Texture2D = extern struct {
    vtable: [*]const *const anyopaque,

    /// __uuidof(ID3D11Device) = `"6f15aaf2-d208-4e89-9ab4-489535d34f9c"`
    pub const UUID = &GUID{
        .Data1 = 0x6f15aaf2,
        .Data2 = 0xd208,
        .Data3 = 0x4e89,
        .Data4 = .{
            0x9a, 0xb4,
            0x48, 0x95,
            0x35, 0xd3,
            0x4f, 0x9c,
        },
    };

    pub inline fn Release(self: *ID3D11Texture2D) void {
        const FnType = fn (*ID3D11Texture2D) callconv(.winapi) ULONG;
        const release: *const FnType = @ptrCast(self.vtable[2]);

        _ = release(self);
    }

    pub fn GetDevice(self: *ID3D11Texture2D) *ID3D11Device {
        const FnType = fn (*ID3D11Texture2D, **ID3D11Device) callconv(.winapi) void;
        const get_device: *const FnType = @ptrCast(self.vtable[3]);

        var pDevice: *ID3D11Device = undefined;
        get_device(self, &pDevice);

        return pDevice;
    }
};

pub const ID3D11Device = extern struct {
    vtable: [*]const *const anyopaque,

    /// __uuidof(ID3D11Device) = `"db6f6ddb-ac77-4e88-8253-819df9bbf140"`
    pub const UUID = &GUID{
        .Data1 = 0xdb6f6ddb,
        .Data2 = 0xac77,
        .Data3 = 0x4e88,
        .Data4 = .{
            0x82, 0x53,
            0x81, 0x9d,
            0xf9, 0xbb,
            0xf1, 0x40,
        },
    };

    pub inline fn Release(self: *ID3D11Device) void {
        const FnType = fn (*ID3D11Device) callconv(.winapi) ULONG;
        const release: *const FnType = @ptrCast(self.vtable[2]);

        _ = release(self);
    }

    pub const CreateBufferError = error{Unexpected};

    pub fn CreateBuffer(
        self: *ID3D11Device,
        pDesc: *D3D11_BUFFER_DESC,
        pInitialData: ?*const D3D11_SUBRESOURCE_DATA,
        ppBuffer: **ID3D11Buffer,
    ) CreateBufferError!void {
        const FnType = fn (*ID3D11Device, *D3D11_BUFFER_DESC, ?*const D3D11_SUBRESOURCE_DATA, ?**ID3D11Buffer) callconv(.winapi) HRESULT;
        const create_buffer: *const FnType = @ptrCast(self.vtable[3]);

        const hr = create_buffer(self, pDesc, pInitialData, ppBuffer);
        return switch (hr) {
            .S_OK => {},
            else => |err| unexpectedError(err),
        };
    }

    pub const CreateTexture2DError = error{
        OutOfMemory,
        Unexpected,
    };

    pub fn CreateTexture2D(
        self: *ID3D11Device,
        pDesc: *const D3D11_TEXTURE2D_DESC,
        pInitialData: ?*const D3D11_SUBRESOURCE_DATA,
        ppTexture2D: **ID3D11Texture2D,
    ) CreateTexture2DError!void {
        const FnType = fn (*ID3D11Device, *const D3D11_TEXTURE2D_DESC, ?*const D3D11_SUBRESOURCE_DATA, **ID3D11Texture2D) callconv(.winapi) HRESULT;
        const create_texture_2d: *const FnType = @ptrCast(self.vtable[5]);

        const hr = create_texture_2d(self, pDesc, pInitialData, ppTexture2D);
        return switch (hr) {
            .S_OK => {},
            .E_OUTOFMEMORY => error.OutOfMemory,
            else => |err| unexpectedError(err),
        };
    }

    pub const CreateShaderResourceViewError = error{
        OutOfMemory,
        Unexpected,
    };

    pub fn CreateShaderResourceView(
        self: *ID3D11Device,
        pResource: *ID3D11Resource,
        pDesc: ?*const D3D11_SHADER_RESOURCE_VIEW_DESC,
        ppSRView: **ID3D11ShaderResourceView,
    ) CreateShaderResourceViewError!void {
        const FnType = fn (*ID3D11Device, *ID3D11Resource, ?*const D3D11_SHADER_RESOURCE_VIEW_DESC, **ID3D11ShaderResourceView) callconv(.winapi) HRESULT;
        const create_shader_resource_view: *const FnType = @ptrCast(self.vtable[7]);

        const hr = create_shader_resource_view(self, pResource, pDesc, ppSRView);
        return switch (hr) {
            .S_OK => {},
            .E_OUTOFMEMORY => error.OutOfMemory,
            else => |err| unexpectedError(err),
        };
    }

    pub const CreateRenderTargetViewError = error{Unexpected};

    pub fn CreateRenderTargetView(
        self: *ID3D11Device,
        pResource: *ID3D11Resource,
        pDesc: ?*const D3D11_RENDER_TARGET_VIEW_DESC,
        ppRTView: **ID3D11RenderTargetView,
    ) CreateRenderTargetViewError!void {
        const FnType = fn (*ID3D11Device, *ID3D11Resource, ?*const D3D11_RENDER_TARGET_VIEW_DESC, ?**ID3D11RenderTargetView) callconv(.winapi) HRESULT;
        const create_render_target_view: *const FnType = @ptrCast(self.vtable[9]);

        const hr = create_render_target_view(self, pResource, pDesc, ppRTView);
        return switch (hr) {
            .S_OK => {},
            else => |err| unexpectedError(err),
        };
    }

    pub const CreateInputLayoutError = error{Unexpected};

    pub fn CreateInputLayout(
        self: *ID3D11Device,
        InputElementDescs: []const D3D11_INPUT_ELEMENT_DESC,
        ShaderBytecodeWithInputSignature: []const u8,
        ppInputLayout: ?**ID3D11InputLayout,
    ) !void {
        const FnType = fn (*ID3D11Device, [*]const D3D11_INPUT_ELEMENT_DESC, UINT, [*]const u8, SIZE_T, ?**ID3D11InputLayout) callconv(.winapi) HRESULT;
        const create_input_layout: *const FnType = @ptrCast(self.vtable[11]);

        const hr = create_input_layout(self, InputElementDescs.ptr, @intCast(InputElementDescs.len), ShaderBytecodeWithInputSignature.ptr, ShaderBytecodeWithInputSignature.len, ppInputLayout);
        return switch (hr) {
            .S_OK => {},
            else => |err| unexpectedError(err),
        };
    }

    pub const CreateShaderError = error{Unexpected};

    pub fn CreateVertexShader(
        self: *ID3D11Device,
        ShaderBytecode: []const u8,
        pClassLinkage: ?*ID3D11ClassLinkage,
        ppVertexShader: **ID3D11VertexShader,
    ) CreateShaderError!void {
        const FnType = fn (*ID3D11Device, LPCVOID, SIZE_T, ?*ID3D11ClassLinkage, **ID3D11VertexShader) callconv(.winapi) HRESULT;
        const create_vertex_shader: *const FnType = @ptrCast(self.vtable[12]);

        const hr = create_vertex_shader(self, ShaderBytecode.ptr, ShaderBytecode.len, pClassLinkage, ppVertexShader);
        return switch (hr) {
            .S_OK => {},
            else => |err| unexpectedError(err),
        };
    }

    pub fn CreatePixelShader(
        self: *ID3D11Device,
        ShaderBytecode: []const u8,
        pClassLinkage: ?*ID3D11ClassLinkage,
        ppPixelShader: **ID3D11PixelShader,
    ) CreateShaderError!void {
        const FnType = fn (*ID3D11Device, LPCVOID, SIZE_T, ?*ID3D11ClassLinkage, **ID3D11PixelShader) callconv(.winapi) HRESULT;
        const create_pixel_shader: *const FnType = @ptrCast(self.vtable[15]);

        const hr = create_pixel_shader(self, ShaderBytecode.ptr, ShaderBytecode.len, pClassLinkage, ppPixelShader);
        return switch (hr) {
            .S_OK => {},
            else => |err| unexpectedError(err),
        };
    }

    pub const CreateBlendStateError = error{Unexpected};

    pub fn CreateBlendState(
        self: *ID3D11Device,
        pBlendStateDesc: *const D3D11_BLEND_DESC,
        ppBlendState: **ID3D11BlendState,
    ) CreateBlendStateError!void {
        const FnType = fn (*ID3D11Device, *const D3D11_BLEND_DESC, **ID3D11BlendState) callconv(.winapi) HRESULT;
        const create_blend_state: *const FnType = @ptrCast(self.vtable[20]);

        const hr = create_blend_state(self, pBlendStateDesc, ppBlendState);
        return switch (hr) {
            .S_OK => {},
            else => |err| unexpectedError(err),
        };
    }

    pub const CreateSamplerStateError = error{Unexpected};

    pub fn CreateSamplerState(
        self: *ID3D11Device,
        pSamplerDesc: *const D3D11_SAMPLER_DESC,
        ppSamplerState: **ID3D11SamplerState,
    ) CreateSamplerStateError!void {
        const FnType = fn (*ID3D11Device, *const D3D11_SAMPLER_DESC, **ID3D11SamplerState) callconv(.winapi) HRESULT;
        const create_sampler_state: *const FnType = @ptrCast(self.vtable[23]);

        const hr = create_sampler_state(self, pSamplerDesc, ppSamplerState);
        return switch (hr) {
            .S_OK => {},
            else => |err| unexpectedError(err),
        };
    }

    pub fn GetImmediateContext(self: *ID3D11Device) *ID3D11DeviceContext {
        const FnType = fn (*ID3D11Device, **ID3D11DeviceContext) callconv(.winapi) void;
        const get_immediate_context: *const FnType = @ptrCast(self.vtable[40]);

        var pImmediateContext: *ID3D11DeviceContext = undefined;
        get_immediate_context(self, &pImmediateContext);

        return pImmediateContext;
    }
};

pub const ID3D11DeviceContext = extern struct {
    vtable: [*]const *const anyopaque,

    pub inline fn Release(self: *ID3D11DeviceContext) void {
        const FnType = fn (*ID3D11DeviceContext) callconv(.winapi) ULONG;
        const release: *const FnType = @ptrCast(self.vtable[2]);

        _ = release(self);
    }

    pub inline fn VSSetConstantBuffers(
        self: *ID3D11DeviceContext,
        StartSlot: UINT,
        ConstantBuffers: []const ?*ID3D11Buffer,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, ?[*]const ?*ID3D11Buffer) callconv(.winapi) void;
        const vs_set_constant_buffers: *const FnType = @ptrCast(self.vtable[7]);

        vs_set_constant_buffers(self, StartSlot, @intCast(ConstantBuffers.len), ConstantBuffers.ptr);
    }

    pub inline fn PSSetShaderResources(
        self: *ID3D11DeviceContext,
        StartSlot: UINT,
        ShaderResourceViews: []const ?*ID3D11ShaderResourceView,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, ?[*]const ?*ID3D11ShaderResourceView) callconv(.winapi) void;
        const ps_set_shader_resources: *const FnType = @ptrCast(self.vtable[8]);

        ps_set_shader_resources(self, StartSlot, @intCast(ShaderResourceViews.len), ShaderResourceViews.ptr);
    }

    pub inline fn PSSetShader(
        self: *ID3D11DeviceContext,
        pPixelShader: ?*ID3D11PixelShader,
        ClassInstances: ?[]const *ID3D11ClassInstance,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, ?*ID3D11PixelShader, ?[*]const *ID3D11ClassInstance, UINT) callconv(.winapi) void;
        const ps_set_shader: *const FnType = @ptrCast(self.vtable[9]);

        const class_instance_ptr = if (ClassInstances) |ci| ci.ptr else null;
        const class_instances_len = if (ClassInstances) |ci| ci.len else 0;

        ps_set_shader(self, pPixelShader, class_instance_ptr, @intCast(class_instances_len));
    }

    pub inline fn PSSetSamplers(
        self: *ID3D11DeviceContext,
        StartSlot: UINT,
        Samplers: []const ?*ID3D11SamplerState,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, [*]const ?*ID3D11SamplerState) callconv(.winapi) void;
        const ps_set_samplers: *const FnType = @ptrCast(self.vtable[10]);

        ps_set_samplers(self, StartSlot, @intCast(Samplers.len), Samplers.ptr);
    }

    pub inline fn VSSetShader(
        self: *ID3D11DeviceContext,
        pVertexShader: ?*ID3D11VertexShader,
        ClassInstances: ?[]const *ID3D11ClassInstance,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, ?*ID3D11VertexShader, ?[*]const *ID3D11ClassInstance, UINT) callconv(.winapi) void;
        const vs_set_shader: *const FnType = @ptrCast(self.vtable[11]);

        const class_instance_ptr = if (ClassInstances) |ci| ci.ptr else null;
        const class_instances_len = if (ClassInstances) |ci| ci.len else 0;

        vs_set_shader(self, pVertexShader, class_instance_ptr, @intCast(class_instances_len));
    }

    pub inline fn DrawIndexed(
        self: *ID3D11DeviceContext,
        IndexCount: UINT,
        StartIndexLocation: UINT,
        BaseVertexLocation: UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, UINT) callconv(.winapi) void;
        const draw_indexed: *const FnType = @ptrCast(self.vtable[12]);

        draw_indexed(self, IndexCount, StartIndexLocation, BaseVertexLocation);
    }

    pub inline fn Draw(
        self: *ID3D11DeviceContext,
        VertexCount: UINT,
        StartVertexLocation: UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, UINT) callconv(.winapi) void;
        const draw: *const FnType = @ptrCast(self.vtable[13]);

        draw(self, VertexCount, StartVertexLocation);
    }

    pub const MapError = error{
        OutOfMemory,
        Unexpected,
    };

    pub fn Map(
        self: *ID3D11DeviceContext,
        pResource: *ID3D11Resource,
        Subresource: UINT,
        MapType: D3D11_MAP,
        MapFlags: UINT,
        pMappedResource: *D3D11_MAPPED_SUBRESOURCE,
    ) MapError!void {
        const FnType = fn (*ID3D11DeviceContext, *ID3D11Resource, UINT, D3D11_MAP, UINT, ?*D3D11_MAPPED_SUBRESOURCE) callconv(.winapi) HRESULT;
        const map: *const FnType = @ptrCast(self.vtable[14]);

        const hr = map(self, pResource, Subresource, MapType, MapFlags, pMappedResource);
        return switch (hr) {
            .S_OK => {},
            .E_OUTOFMEMORY => error.OutOfMemory,
            else => |err| unexpectedError(err),
        };
    }

    pub inline fn Unmap(
        self: *ID3D11DeviceContext,
        pResource: *ID3D11Resource,
        Subresource: UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *ID3D11Resource, UINT) callconv(.winapi) void;
        const unmap: *const FnType = @ptrCast(self.vtable[15]);

        unmap(self, pResource, Subresource);
    }

    pub inline fn IASetInputLayout(self: *ID3D11DeviceContext, pInputLayout: ?*ID3D11InputLayout) void {
        const FnType = fn (*ID3D11DeviceContext, ?*ID3D11InputLayout) callconv(.winapi) void;
        const ia_set_input_layout: *const FnType = @ptrCast(self.vtable[17]);

        ia_set_input_layout(self, pInputLayout);
    }

    pub inline fn IASetVertexBuffers(
        self: *ID3D11DeviceContext,
        StartSlot: UINT,
        VertexBuffers: []const ?*ID3D11Buffer,
        Strides: []const UINT,
        Offsets: []const UINT,
    ) void {
        assert(VertexBuffers.len == Strides.len);
        assert(VertexBuffers.len == Offsets.len);

        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, [*]const ?*ID3D11Buffer, [*]const UINT, [*]const UINT) callconv(.winapi) void;
        const ia_set_vertex_buffers: *const FnType = @ptrCast(self.vtable[18]);

        ia_set_vertex_buffers(self, StartSlot, @intCast(VertexBuffers.len), VertexBuffers.ptr, Strides.ptr, Offsets.ptr);
    }

    pub inline fn IASetIndexBuffer(
        self: *ID3D11DeviceContext,
        pIndexBuffer: ?*ID3D11Buffer,
        Format: DXGI_FORMAT,
        Offset: UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, ?*ID3D11Buffer, DXGI_FORMAT, UINT) callconv(.winapi) void;
        const ia_set_index_buffer: *const FnType = @ptrCast(self.vtable[19]);

        ia_set_index_buffer(self, pIndexBuffer, Format, Offset);
    }

    pub inline fn IASetPrimitiveTopology(self: *ID3D11DeviceContext, Topology: D3D11_PRIMITIVE_TOPOLOGY) void {
        const FnType = fn (*ID3D11DeviceContext, D3D11_PRIMITIVE_TOPOLOGY) callconv(.winapi) void;
        const ia_set_primitive_topology: *const FnType = @ptrCast(self.vtable[24]);

        ia_set_primitive_topology(self, Topology);
    }

    pub inline fn OMSetRenderTargets(
        self: *ID3D11DeviceContext,
        RenderTargetViews: []const ?*ID3D11RenderTargetView,
        pDepthStencilView: ?*ID3D11DepthStencilView,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, [*]const ?*ID3D11RenderTargetView, ?*ID3D11DepthStencilView) callconv(.winapi) void;
        const om_set_render_targets: *const FnType = @ptrCast(self.vtable[33]);

        om_set_render_targets(self, @intCast(RenderTargetViews.len), RenderTargetViews.ptr, pDepthStencilView);
    }

    pub inline fn OMSetBlendState(
        self: *ID3D11DeviceContext,
        pBlendState: ?*ID3D11BlendState,
        BlendFactor: *const [4]f32,
        SampleMask: UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, ?*ID3D11BlendState, ?*const [4]f32, UINT) callconv(.winapi) void;
        const om_set_blend_state: *const FnType = @ptrCast(self.vtable[35]);

        om_set_blend_state(self, pBlendState, BlendFactor, SampleMask);
    }

    pub inline fn RSSetViewports(self: *ID3D11DeviceContext, Viewports: []const D3D11_VIEWPORT) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, [*]const D3D11_VIEWPORT) callconv(.winapi) void;
        const rs_set_viewports: *const FnType = @ptrCast(self.vtable[44]);

        rs_set_viewports(self, @intCast(Viewports.len), Viewports.ptr);
    }

    pub inline fn ClearRenderTargetView(
        self: *ID3D11DeviceContext,
        pRenderTargetView: *ID3D11RenderTargetView,
        ColorRGBA: [4]f32,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *ID3D11RenderTargetView, *const [4]f32) callconv(.winapi) void;
        const clear_render_target_view: *const FnType = @ptrCast(self.vtable[50]);

        clear_render_target_view(self, pRenderTargetView, &ColorRGBA);
    }

    pub inline fn VSGetConstantBuffers(
        self: *ID3D11DeviceContext,
        StartSlot: UINT,
        ConstantBuffers: []?*ID3D11Buffer,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, [*]?*ID3D11Buffer) callconv(.winapi) void;
        const vs_get_constant_buffers: *const FnType = @ptrCast(self.vtable[72]);

        vs_get_constant_buffers(self, StartSlot, @intCast(ConstantBuffers.len), ConstantBuffers.ptr);
    }

    pub inline fn PSGetShaderResources(
        self: *ID3D11DeviceContext,
        StartSlot: UINT,
        ShaderResourceViews: []?*ID3D11ShaderResourceView,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, [*]?*ID3D11ShaderResourceView) callconv(.winapi) void;
        const ps_get_shader_resources: *const FnType = @ptrCast(self.vtable[73]);

        ps_get_shader_resources(self, StartSlot, @intCast(ShaderResourceViews.len), ShaderResourceViews.ptr);
    }

    pub inline fn PSGetShader(
        self: *ID3D11DeviceContext,
        ppPixelShader: *?*ID3D11PixelShader,
        ppClassInstances: [*]*ID3D11ClassInstance,
        pNumClassInstances: *UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *?*ID3D11PixelShader, [*]*ID3D11ClassInstance, ?*UINT) callconv(.winapi) void;
        const ps_get_shader: *const FnType = @ptrCast(self.vtable[74]);

        ps_get_shader(self, ppPixelShader, ppClassInstances, pNumClassInstances);
    }

    pub inline fn PSGetSamplers(
        self: *ID3D11DeviceContext,
        StartSlot: UINT,
        Samplers: []?*ID3D11SamplerState,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, [*]?*ID3D11SamplerState) callconv(.winapi) void;
        const ps_get_samplers: *const FnType = @ptrCast(self.vtable[75]);

        ps_get_samplers(self, StartSlot, @intCast(Samplers.len), Samplers.ptr);
    }

    pub inline fn VSGetShader(
        self: *ID3D11DeviceContext,
        ppVertexShader: *?*ID3D11VertexShader,
        ppClassInstances: [*]*ID3D11ClassInstance,
        pNumClassInstances: *UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *?*ID3D11VertexShader, [*]*ID3D11ClassInstance, ?*UINT) callconv(.winapi) void;
        const vs_get_shader: *const FnType = @ptrCast(self.vtable[76]);

        vs_get_shader(self, ppVertexShader, ppClassInstances, pNumClassInstances);
    }

    pub inline fn IAGetInputLayout(self: *ID3D11DeviceContext, ppInputLayout: *?*ID3D11InputLayout) void {
        const FnType = fn (*ID3D11DeviceContext, *?*ID3D11InputLayout) callconv(.winapi) void;
        const ia_get_input_layout: *const FnType = @ptrCast(self.vtable[78]);

        ia_get_input_layout(self, ppInputLayout);
    }

    pub inline fn IAGetVertexBuffers(
        self: *ID3D11DeviceContext,
        StartSlot: UINT,
        VertexBuffers: []?*ID3D11Buffer,
        Strides: []UINT,
        Offsets: []UINT,
    ) void {
        assert(VertexBuffers.len == Strides.len);
        assert(VertexBuffers.len == Offsets.len);

        const FnType = fn (*ID3D11DeviceContext, UINT, UINT, [*]?*ID3D11Buffer, [*]UINT, [*]UINT) callconv(.winapi) void;
        const ia_get_vertex_buffers: *const FnType = @ptrCast(self.vtable[79]);

        ia_get_vertex_buffers(self, StartSlot, @intCast(VertexBuffers.len), VertexBuffers.ptr, Strides.ptr, Offsets.ptr);
    }

    pub inline fn IAGetIndexBuffer(
        self: *ID3D11DeviceContext,
        pIndexBuffer: *?*ID3D11Buffer,
        Format: *DXGI_FORMAT,
        Offset: *UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *?*ID3D11Buffer, *DXGI_FORMAT, *UINT) callconv(.winapi) void;
        const ia_get_index_buffer: *const FnType = @ptrCast(self.vtable[80]);

        ia_get_index_buffer(self, pIndexBuffer, Format, Offset);
    }

    pub inline fn GSGetShader(
        self: *ID3D11DeviceContext,
        ppGeometryShader: *?*ID3D11GeometryShader,
        ppClassInstances: [*]*ID3D11ClassInstance,
        pNumClassInstances: *UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *?*ID3D11GeometryShader, [*]*ID3D11ClassInstance, ?*UINT) callconv(.winapi) void;
        const gs_get_shader: *const FnType = @ptrCast(self.vtable[82]);

        gs_get_shader(self, ppGeometryShader, ppClassInstances, pNumClassInstances);
    }

    pub inline fn IAGetPrimitiveTopology(self: *ID3D11DeviceContext, pTopology: *D3D11_PRIMITIVE_TOPOLOGY) void {
        const FnType = fn (*ID3D11DeviceContext, *D3D11_PRIMITIVE_TOPOLOGY) callconv(.winapi) void;
        const ia_get_primitive_topology: *const FnType = @ptrCast(self.vtable[83]);

        ia_get_primitive_topology(self, pTopology);
    }

    pub inline fn OMGetRenderTargets(
        self: *ID3D11DeviceContext,
        RenderTargetViews: []?*ID3D11RenderTargetView,
        ppDepthStencilView: ?*?*ID3D11DepthStencilView,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, UINT, [*]?*ID3D11RenderTargetView, ?*?*ID3D11DepthStencilView) callconv(.winapi) void;
        const om_get_render_targets: *const FnType = @ptrCast(self.vtable[89]);

        om_get_render_targets(self, @intCast(RenderTargetViews.len), RenderTargetViews.ptr, ppDepthStencilView);
    }

    pub inline fn OMGetBlendState(
        self: *ID3D11DeviceContext,
        ppBlendState: *?*ID3D11BlendState,
        BlendFactor: *[4]FLOAT,
        pSampleMask: *UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *?*ID3D11BlendState, *[4]FLOAT, *UINT) callconv(.winapi) void;
        const om_get_blend_state: *const FnType = @ptrCast(self.vtable[91]);

        om_get_blend_state(self, ppBlendState, BlendFactor, pSampleMask);
    }

    pub inline fn OMGetDepthStencilState(
        self: *ID3D11DeviceContext,
        ppDepthStencilState: *?*ID3D11DepthStencilState,
        pStencilRef: *UINT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *?*ID3D11DepthStencilState, *UINT) callconv(.winapi) void;
        const om_get_depth_stencil_state: *const FnType = @ptrCast(self.vtable[92]);

        om_get_depth_stencil_state(self, ppDepthStencilState, pStencilRef);
    }

    pub inline fn RSGetState(self: *ID3D11DeviceContext, ppRasterizerState: *?*ID3D11RasterizerState) void {
        const FnType = fn (*ID3D11DeviceContext, *?*ID3D11RasterizerState) callconv(.winapi) void;
        const rs_get_state: *const FnType = @ptrCast(self.vtable[94]);

        rs_get_state(self, ppRasterizerState);
    }

    pub inline fn RSGetViewports(
        self: *ID3D11DeviceContext,
        pNumViewports: *UINT,
        pViewports: [*]D3D11_VIEWPORT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *UINT, ?[*]D3D11_VIEWPORT) callconv(.winapi) void;
        const rs_get_viewports: *const FnType = @ptrCast(self.vtable[95]);

        rs_get_viewports(self, pNumViewports, pViewports);
    }

    pub inline fn RSGetScissorRects(
        self: *ID3D11DeviceContext,
        pNumRects: *UINT,
        pRects: [*]D3D11_RECT,
    ) void {
        const FnType = fn (*ID3D11DeviceContext, *UINT, ?[*]D3D11_RECT) callconv(.winapi) void;
        const rs_get_scissor_rects: *const FnType = @ptrCast(self.vtable[96]);

        rs_get_scissor_rects(self, pNumRects, pRects);
    }
};

pub extern "d3d11" fn D3D11CreateDeviceAndSwapChain(
    pAdapter: ?*IDXGIAdapter,
    DriverType: D3D_DRIVER_TYPE,
    Software: ?HMODULE,
    Flags: UINT,
    pFeatureLevels: ?[*]const D3D_FEATURE_LEVEL,
    FeatureLevels: UINT,
    SDKVersion: UINT,
    pSwapChainDesc: ?*const DXGI_SWAP_CHAIN_DESC,
    ppSwapChain: **IDXGISwapChain,
    ppDevice: **ID3D11Device,
    pFeatureLevel: ?*D3D_FEATURE_LEVEL,
    ppImmediateContext: **ID3D11DeviceContext,
) callconv(.winapi) D3D11_ERROR;

pub const UnexpectedError = error{
    Unexpected,
};

pub fn unexpectedError(err: D3D11_ERROR) UnexpectedError {
    @branchHint(.cold);
    if (std.options.unexpected_error_tracing) {
        std.debug.print("error.Unexpected D3D11_ERROR=0x{x} ({s})\n", .{
            @intFromEnum(err),
            std.enums.tagName(D3D11_ERROR, err) orelse "<unnamed>",
        });
        std.debug.dumpCurrentStackTrace(.{ .first_address = @returnAddress() });
    }
    return error.Unexpected;
}
