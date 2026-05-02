const Backend = @This();

const std = @import("std");
const windows = @import("../../windows.zig");
const gfx = @import("../../graphics.zig");

const dxgi = windows.dxgi;
const d3d11 = windows.d3d11;
const d3dcommon = windows.d3dcommon;
const d3dcompiler = windows.d3dcompiler;

device: *d3d11.ID3D11Device,
context: *d3d11.ID3D11DeviceContext,
render_target_view: *d3d11.ID3D11RenderTargetView,
vertex_shader: *d3d11.ID3D11VertexShader,
pixel_shader: *d3d11.ID3D11PixelShader,
blend_state: *d3d11.ID3D11BlendState,
input_layout: *d3d11.ID3D11InputLayout,
constant_buffer: *d3d11.ID3D11Buffer,
vertex_buffer: *d3d11.ID3D11Buffer,
index_buffer: *d3d11.ID3D11Buffer,
sampler: *d3d11.ID3D11SamplerState,

interface: gfx.Backend,

pub fn init(swap_chain: *dxgi.IDXGISwapChain) !Backend {
    const device = try swap_chain.GetDevice(d3d11.ID3D11Device);
    errdefer device.Release();

    const context = device.GetImmediateContext();
    errdefer context.Release();

    const back_buffer = try swap_chain.GetBuffer(0, d3d11.ID3D11Texture2D);
    defer back_buffer.Release();

    const render_target_view = try device.CreateRenderTargetView(@ptrCast(back_buffer), null);
    errdefer render_target_view.Release();

    const vs = @embedFile("../shaders/vs.hlsl");

    var vertex_blob: *d3dcommon.ID3DBlob = undefined;
    var vertex_shader: *d3d11.ID3D11VertexShader = undefined;

    switch (d3dcompiler.D3DCompile(vs, vs.len, null, null, null, "VS", "vs_5_0", 0, 0, &vertex_blob, null)) {
        .OK => {},
        .OUTOFMEMORY => return error.OutOfMemory,
        else => |e| return d3d11.unexpectedError(e),
    }
    defer vertex_blob.Release();

    try device.CreateVertexShader(vertex_blob.slice(), null, &vertex_shader);
    errdefer vertex_shader.Release();

    const ps = @embedFile("../shaders/ps.hlsl");

    var pixel_blob: *d3dcommon.ID3DBlob = undefined;
    var pixel_shader: *d3d11.ID3D11VertexShader = undefined;

    switch (d3dcompiler.D3DCompile(ps, ps.len, null, null, null, "PS", "ps_5_0", 0, 0, &pixel_blob, null)) {
        .OK => {},
        .OUTOFMEMORY => return error.OutOfMemory,
        else => |e| return d3d11.unexpectedError(e),
    }
    defer pixel_blob.Release();

    try device.CreateVertexShader(pixel_blob.slice(), null, &pixel_shader);
    errdefer pixel_shader.Release();

    var blend_state: *d3d11.ID3D11BlendState = undefined;
    var blend_desc = std.mem.zeroes(d3d11.D3D11_BLEND_DESC);

    blend_desc.AlphaToCoverageEnable = .FALSE;
    blend_desc.RenderTarget[0].BlendEnable = .TRUE;
    blend_desc.RenderTarget[0].SrcBlend = d3d11.D3D11_BLEND_SRC_ALPHA;
    blend_desc.RenderTarget[0].DestBlend = d3d11.D3D11_BLEND_INV_SRC_ALPHA;
    blend_desc.RenderTarget[0].BlendOp = d3d11.D3D11_BLEND_OP_ADD;
    blend_desc.RenderTarget[0].SrcBlendAlpha = d3d11.D3D11_BLEND_ONE;
    blend_desc.RenderTarget[0].DestBlendAlpha = d3d11.D3D11_BLEND_INV_SRC_ALPHA;
    blend_desc.RenderTarget[0].BlendOpAlpha = d3d11.D3D11_BLEND_OP_ADD;
    blend_desc.RenderTarget[0].RenderTargetWriteMask = d3d11.D3D11_COLOR_WRITE_ENABLE_ALL;

    try device.CreateBlendState(&blend_desc, &blend_state);
    errdefer blend_state.Release();

    const input_elements = &[_]d3d11.D3D11_INPUT_ELEMENT_DESC{
        .{
            .SemanticName = "POSITION",
            .SemanticIndex = 0,
            .Format = dxgi.DXGI_FORMAT_R32G32_FLOAT,
            .InputSlot = 0,
            .AlignedByteOffset = 0,
            .InputSlotClass = d3d11.D3D11_INPUT_PER_VERTEX_DATA,
            .InstanceDataStepRate = 0,
        },
        .{
            .SemanticName = "TEXCOORD",
            .SemanticIndex = 0,
            .Format = dxgi.DXGI_FORMAT_R32G32_FLOAT,
            .InputSlot = 0,
            .AlignedByteOffset = 8,
            .InputSlotClass = d3d11.D3D11_INPUT_PER_VERTEX_DATA,
            .InstanceDataStepRate = 0,
        },
        .{
            .SemanticName = "COLOR",
            .SemanticIndex = 0,
            .Format = dxgi.DXGI_FORMAT_R32_UINT,
            .InputSlot = 0,
            .AlignedByteOffset = 16,
            .InputSlotClass = d3d11.D3D11_INPUT_PER_VERTEX_DATA,
            .InstanceDataStepRate = 0,
        },
        .{
            .SemanticName = "TEXCOORD",
            .SemanticIndex = 1,
            .Format = dxgi.DXGI_FORMAT_R8_UINT,
            .InputSlot = 0,
            .AlignedByteOffset = 20,
            .InputSlotClass = d3d11.D3D11_INPUT_PER_VERTEX_DATA,
            .InstanceDataStepRate = 0,
        },
    };

    var input_layout: *d3d11.ID3D11InputLayout = undefined;

    try device.CreateInputLayout(input_elements, vertex_blob.slice(), &input_layout);
    errdefer input_layout.Release();

    var constant_buffer: *d3d11.ID3D11Buffer = undefined;
    var constant_buffer_desc = std.mem.zeroes(d3d11.D3D11_BUFFER_DESC);

    constant_buffer_desc.Usage = d3d11.D3D11_USAGE_DYNAMIC;
    constant_buffer_desc.CPUAccessFlags = d3d11.D3D11_CPU_ACCESS_WRITE;
    constant_buffer_desc.ByteWidth = @sizeOf(gfx.ConstantBuffer);
    constant_buffer_desc.BindFlags = d3d11.D3D11_BIND_CONSTANT_BUFFER;

    try device.CreateBuffer(&constant_buffer_desc, null, &constant_buffer);
    errdefer constant_buffer.Release();

    var vertex_buffer: *d3d11.ID3D11Buffer = undefined;
    var vertex_buffer_desc = std.mem.zeroes(d3d11.D3D11_BUFFER_DESC);

    vertex_buffer_desc.Usage = d3d11.D3D11_USAGE_DYNAMIC;
    vertex_buffer_desc.CPUAccessFlags = d3d11.D3D11_CPU_ACCESS_WRITE;
    vertex_buffer_desc.ByteWidth = gfx.max_verticies * @sizeOf(gfx.DrawVertex);
    vertex_buffer_desc.BindFlags = d3d11.D3D11_BIND_VERTEX_BUFFER;

    try device.CreateBuffer(&vertex_buffer_desc, null, &vertex_buffer);
    errdefer vertex_buffer.Release();

    var index_buffer: *d3d11.ID3D11Buffer = undefined;
    var index_buffer_desc = std.mem.zeroes(d3d11.D3D11_BUFFER_DESC);

    index_buffer_desc.Usage = d3d11.D3D11_USAGE_DYNAMIC;
    index_buffer_desc.CPUAccessFlags = d3d11.D3D11_CPU_ACCESS_WRITE;
    index_buffer_desc.ByteWidth = gfx.max_indicies * @sizeOf(gfx.DrawIndex);
    index_buffer_desc.BindFlags = d3d11.D3D11_BIND_INDEX_BUFFER;

    try device.CreateBuffer(&index_buffer_desc, null, &index_buffer);
    errdefer index_buffer.Release();

    var sampler: *d3d11.ID3D11SamplerState = undefined;
    var sampler_desc = std.mem.zeroes(d3d11.D3D11_SAMPLER_DESC);

    sampler_desc.Filter = d3d11.D3D11_FILTER_MIN_MAG_MIP_LINEAR;
    sampler_desc.AddressU = d3d11.D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler_desc.AddressV = d3d11.D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler_desc.AddressW = d3d11.D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler_desc.MipLODBias = 0.0;
    sampler_desc.ComparisonFunc = d3d11.D3D11_COMPARISON_ALWAYS;
    sampler_desc.MinLOD = 0.0;
    sampler_desc.MaxLOD = 0.0;

    try device.CreateSamplerState(&sampler_desc, &sampler);
    errdefer sampler.Release();

    return .{
        .device = device,
        .context = context,
        .render_target_view = render_target_view,
        .vertex_shader = vertex_shader,
        .pixel_shader = pixel_shader,
        .blend_state = blend_state,
        .input_layout = input_layout,
        .constant_buffer = constant_buffer,
        .vertex_buffer = vertex_buffer,
        .index_buffer = index_buffer,
        .sampler = sampler,
        .interface = .{ 
            .vtable = &.{
                .draw = draw,
            },
        },
    };
}

pub fn deinit(b: *Backend) void {
    b.sampler.Release();
    b.index_buffer.Release();
    b.vertex_buffer.Release();
    b.constant_buffer.Release();
    b.input_layout.Release();
    b.blend_state.Release();
    b.pixel_shader.Release();
    b.vertex_shader.Release();
    b.render_target_view.Release();
    b.context.Release();
    b.device.Release();
    b.* = undefined;
}

fn draw(gfx_backend: *gfx.Backend) gfx.Backend.DrawError!void {
    const b: *Backend = @alignCast(@fieldParentPtr("interface", gfx_backend));

    b.context.OMSetRenderTargets((&b.render_target_view)[0..1], null);
    b.context.OMSetBlendState(b.blend_state, &.{ 0.0, 0.0, 0.0, 0.0 }, 0xFFFFFFFF);

    std.debug.print("{}\n", .{b});
}
