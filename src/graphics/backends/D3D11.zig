const Backend = @This();

const std = @import("std");
const windows = @import("../../windows.zig");
const gfx = @import("../../graphics.zig");

const dxgi = windows.dxgi;
const d3d11 = windows.d3d11;
const d3dcommon = windows.d3dcommon;
const d3dcompiler = windows.d3dcompiler;

const assert = std.debug.assert;

device: *d3d11.ID3D11Device,
context: *d3d11.ID3D11DeviceContext,
output_window: windows.HWND,
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

    var desc: dxgi.DXGI_SWAP_CHAIN_DESC = undefined;
    assert(swap_chain.vtable.GetDesc(swap_chain, &desc) == windows.S_OK);

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
        .output_window = desc.OutputWindow,
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
            .viewport = .unset,
            .vtable = &.{
                .draw = draw,
                .image = image,
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

fn draw(gfx_backend: *gfx.Backend, surface: *const gfx.Surface) void {
    const b: *Backend = @alignCast(@fieldParentPtr("interface", gfx_backend));

    {
        const width: f32 = @floatFromInt(gfx_backend.viewport.width);
        const height: f32 = @floatFromInt(gfx_backend.viewport.height);

        var mapped_resource: d3d11.D3D11_MAPPED_SUBRESOURCE = undefined;

        b.context.Map(@ptrCast(b.constant_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &mapped_resource);
        defer b.context.Unmap(@ptrCast(b.constant_buffer), 0);

        const constant_buffer: *gfx.ConstantBuffer = @ptrCast(@alignCast(mapped_resource.pData));

        // todo: remove L R T B for W H

        const L = 0.0;
        const R = width;
        const T = 0.0;
        const B = height;

        constant_buffer.mvp = .{
            .{ 2.0 / (R - L), 0.0, 0.0, 0.0 },
            .{ 0.0, 2.0 / (T - B), 0.0, 0.0 },
            .{ 0.0, 0.0, 0.5, 0.0 },
            .{ (R + L) / (L - R), (T + B) / (B - T), 0.5, 1.0 },
        };
    }

    {
        var vertex_resource: d3d11.D3D11_MAPPED_SUBRESOURCE = undefined;
        var index_resource: d3d11.D3D11_MAPPED_SUBRESOURCE = undefined;

        b.context.Map(@ptrCast(b.vertex_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &vertex_resource);
        defer b.context.Unmap(@ptrCast(b.vertex_buffer), 0);

        b.context.Map(@ptrCast(b.index_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &index_resource);
        defer b.context.Unmap(@ptrCast(b.index_buffer), 0);

        // vertex_resource.write(gfx.DrawVertex, verticies, b.max_verticies * @sizeOf(gfx.DrawVertex));
        // index_resource.write(gfx.DrawIndex, indecies, b.max_indicies * @sizeOf(gfx.DrawIndex));
    }

    // todo: move to threadlocal storage?
    var snapshot: Snapshot = .load(b.context);
    defer snapshot.store(b.context);

    b.context.OMSetRenderTargets((&b.render_target_view)[0..1], null);
    b.context.OMSetBlendState(b.blend_state, &.{ 0.0, 0.0, 0.0, 0.0 }, 0xFFFFFFFF);

    var offset: windows.UINT = 0;
    var stride: windows.UINT = @sizeOf(gfx.DrawVertex);

    b.context.IASetInputLayout(b.input_layout);
    b.context.IASetVertexBuffers(0, (&b.vertex_buffer)[0..1], (&stride)[0..1], (&offset)[0..1]);
    b.context.IASetIndexBuffer(b.index_buffer, if (gfx.DrawIndex == u16) dxgi.DXGI_FORMAT_R16_UINT else @compileError("no corresponding DXGI_FORMAT"), 0);
    b.context.VSSetConstantBuffers(0, (&b.constant_buffer)[0..1]);
    b.context.IASetPrimitiveTopology(d3d11.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    b.context.VSSetShader(b.vertex_shader, null);
    b.context.PSSetShader(b.pixel_shader, null);
    b.context.PSSetSamplers(0, (&b.sampler)[0..1]);

    var index_off: windows.UINT = 0;
    for (surface.draw_commands.items) |cmd| {
        // todo: set srv
        b.context.DrawIndexed(cmd.index_len, index_off, cmd.base_vertex);
        index_off += cmd.index_len;
    }
}

fn image(gfx_backend: *gfx.Backend, image_desc: gfx.Backend.ImageDesc) error{OutOfMemory}!gfx.Image {
    const b: *Backend = @alignCast(@fieldParentPtr("interface", gfx_backend));

    _ = image_desc;

    var tex: *d3d11.ID3D11Texture2D = undefined;
    var srv: *d3d11.ID3D11ShaderResourceView = undefined;

    try b.device.CreateTexture2D(undefined, undefined, &tex);
    try b.device.CreateShaderResourceView(@ptrCast(tex), null, &srv);

    const deinitfn = struct {
        fn inner(i: gfx.Image) void {
            const t: *d3d11.ID3D11Texture2D = @ptrCast(@alignCast(i.tex));
            const s: *d3d11.ID3D11ShaderResourceView = @ptrCast(@alignCast(i.srv));

            _ = t.vtable.Release(t);
            _ = s.vtable.Release(s);
        }
    }.inner;

    return .{
        .tex = tex,
        .srv = srv,

        .deinit = deinitfn,
    };
}




// need loadImage and destroy image that will just return *

const Snapshot = struct {
    scissor_rects_len: windows.UINT = 0,
    viewports_len: windows.UINT = 0,
    scissor_rects: [d3d11.D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]d3d11.D3D11_RECT = undefined,
    viewports: [d3d11.D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]d3d11.D3D11_VIEWPORT = undefined,
    rasterizer_state: ?*d3d11.ID3D11RasterizerState = null,
    blend_state: ?*d3d11.ID3D11BlendState = null,
    blend_factor: [4]windows.FLOAT = .{ 0.0, 0.0, 0.0, 0.0 },
    sample_mask: windows.UINT = 0,
    stencil_ref: windows.UINT = 0,
    render_target_view: ?*d3d11.ID3D11RenderTargetView = null,
    depth_stencil_view: ?*d3d11.ID3D11DepthStencilView = null,
    depth_stencil_state: ?*d3d11.ID3D11DepthStencilState = null,
    shader_resource_view: ?*d3d11.ID3D11ShaderResourceView = null,
    sampler_state: ?*d3d11.ID3D11SamplerState = null,
    pixel_shader: ?*d3d11.ID3D11PixelShader = null,
    vertex_shader: ?*d3d11.ID3D11VertexShader = null,
    geometry_shader: ?*d3d11.ID3D11GeometryShader = null,
    pixel_shader_ins_len: windows.UINT = 0,
    vertex_shader_ins_len: windows.UINT = 0,
    geometry_shader_ins_len: windows.UINT = 0,
    pixel_shader_ins: [256]*d3d11.ID3D11ClassInstance = undefined,
    vertex_shader_ins: [256]*d3d11.ID3D11ClassInstance = undefined,
    geometry_shader_ins: [256]*d3d11.ID3D11ClassInstance = undefined,
    primative_topology: d3d11.D3D11_PRIMITIVE_TOPOLOGY = 0,
    index_buf: ?*d3d11.ID3D11Buffer = null,
    vertex_buf: ?*d3d11.ID3D11Buffer = null,
    constant_buf: ?*d3d11.ID3D11Buffer = null,
    index_buf_offset: windows.UINT = 0,
    vertex_buf_stride: windows.UINT = 0,
    vertex_buf_offset: windows.UINT = 0,
    index_buf_format: dxgi.DXGI_FORMAT = 0,
    input_layout: ?*d3d11.ID3D11InputLayout = null,

    pub fn load(context: *d3d11.ID3D11DeviceContext) Snapshot {
        var snapshot: Snapshot = undefined;

        snapshot.scissor_rects_len = d3d11.D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
        snapshot.viewports_len = d3d11.D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
        snapshot.pixel_shader_ins_len = 256;
        snapshot.vertex_shader_ins_len = 256;
        snapshot.geometry_shader_ins_len = 256;

        context.RSGetScissorRects(&snapshot.scissor_rects_len, &snapshot.scissor_rects);
        context.RSGetViewports(&snapshot.viewports_len, &snapshot.viewports);
        context.RSGetState(&snapshot.rasterizer_state);
        context.OMGetBlendState(&snapshot.blend_state, &snapshot.blend_factor, &snapshot.sample_mask);
        context.OMGetRenderTargets((&snapshot.render_target_view)[0..1], &snapshot.depth_stencil_view);
        context.OMGetDepthStencilState(&snapshot.depth_stencil_state, &snapshot.stencil_ref);
        context.PSGetShaderResources(0, (&snapshot.shader_resource_view)[0..1]);
        context.PSGetSamplers(0, (&snapshot.sampler_state)[0..1]);
        context.PSGetShader(&snapshot.pixel_shader, &snapshot.pixel_shader_ins, &snapshot.pixel_shader_ins_len);
        context.VSGetShader(&snapshot.vertex_shader, &snapshot.vertex_shader_ins, &snapshot.vertex_shader_ins_len);
        context.GSGetShader(&snapshot.geometry_shader, &snapshot.geometry_shader_ins, &snapshot.geometry_shader_ins_len);
        context.VSGetConstantBuffers(0, (&snapshot.constant_buf)[0..1]);
        context.IAGetPrimitiveTopology(&snapshot.primative_topology);
        context.IAGetIndexBuffer(&snapshot.index_buf, &snapshot.index_buf_format, &snapshot.index_buf_offset);
        context.IAGetVertexBuffers(0, (&snapshot.vertex_buf)[0..1], (&snapshot.vertex_buf_stride)[0..1], (&snapshot.index_buf_offset)[0..1]);
        context.IAGetInputLayout(&snapshot.input_layout);

        return snapshot;
    }

    pub fn store(snapshot: *Snapshot, context: *d3d11.ID3D11DeviceContext) void {
        const release = struct {
            fn inner(mb_ctx: ?*anyopaque) void {
                if (mb_ctx) |ctx| {
                    const iunknown: *windows.IUnknown = @ptrCast(@alignCast(ctx));
                    _ = iunknown.vtable.Release(iunknown);
                }
            }
        }.inner;

        // RSSetScissorRects
        context.RSSetViewports(snapshot.viewports[0..snapshot.viewports_len]);
        // RSSetScissorRects
        context.OMSetBlendState(snapshot.blend_state, &snapshot.blend_factor, snapshot.sample_mask);
        context.OMSetRenderTargets((&snapshot.render_target_view)[0..1], snapshot.depth_stencil_view);
        // OMSetDepthStencilState
        context.PSSetShaderResources(0, (&snapshot.shader_resource_view)[0..1]);
        context.PSSetSamplers(0, (&snapshot.sampler_state)[0..1]);
        context.PSSetShader(snapshot.pixel_shader, snapshot.pixel_shader_ins[0..snapshot.pixel_shader_ins_len]);
        context.VSSetShader(snapshot.vertex_shader, snapshot.vertex_shader_ins[0..snapshot.vertex_shader_ins_len]);
        // GSSetShader
        context.IASetPrimitiveTopology(snapshot.primative_topology);
        context.IASetIndexBuffer(snapshot.index_buf, snapshot.index_buf_format, snapshot.index_buf_offset);
        context.IASetVertexBuffers(0, (&snapshot.vertex_buf)[0..1], (&snapshot.vertex_buf_stride)[0..1], (&snapshot.vertex_buf_offset)[0..1]);
        context.VSSetConstantBuffers(0, (&snapshot.constant_buf)[0..1]);
        context.IASetInputLayout(snapshot.input_layout);
        
        release(snapshot.rasterizer_state);
        release(snapshot.blend_state);
        release(snapshot.render_target_view);
        release(snapshot.depth_stencil_view);
        release(snapshot.depth_stencil_state);
        release(snapshot.shader_resource_view);
        release(snapshot.sampler_state);

        release(snapshot.pixel_shader);
        for (0..snapshot.pixel_shader_ins_len) |i| {
            snapshot.pixel_shader_ins[i].Release();
        }

        release(snapshot.vertex_shader);
        for (0..snapshot.vertex_shader_ins_len) |i| {
            snapshot.vertex_shader_ins[i].Release();
        }

        release(snapshot.geometry_shader);
        for (0..snapshot.geometry_shader_ins_len) |i| {
            snapshot.geometry_shader_ins[i].Release();
        }

        release(snapshot.index_buf);
        release(snapshot.vertex_buf);
        release(snapshot.constant_buf);
        release(snapshot.input_layout);

        snapshot.* = undefined;
    }
};
