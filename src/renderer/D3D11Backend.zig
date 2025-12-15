const std = @import("std");
const windows = @import("../windows.zig");
const shared = @import("../gui/shared.zig");
const Backend = @import("Backend.zig");

const mem = std.mem;
const dxgi = windows.dxgi;
const d3d11 = windows.d3d11;
const d3dcommon = windows.d3dcommon;
const d3dcompiler = windows.d3dcompiler;
const Allocator = mem.Allocator;
const assert = std.debug.assert;

const Self = @This();

device: *d3d11.ID3D11Device,
device_context: *d3d11.ID3D11DeviceContext,

target_window: windows.HWND,

render_target_view: *d3d11.ID3D11RenderTargetView,

vertex_shader: *d3d11.ID3D11VertexShader,
pixel_shader: *d3d11.ID3D11PixelShader,

blend_state: *d3d11.ID3D11BlendState,
input_layout: *d3d11.ID3D11InputLayout,

constant_buffer: *d3d11.ID3D11Buffer,
vertex_buffer: *d3d11.ID3D11Buffer,
index_buffer: *d3d11.ID3D11Buffer,

sampler: *d3d11.ID3D11SamplerState,

white_pixel_texture: *d3d11.ID3D11Texture2D,
white_pixel_resource: *d3d11.ID3D11ShaderResourceView,

const DeviceContextState = struct {
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
};

pub const Error = error{
    OutOfMemory,
    Unexpected,
};

pub fn init(swap_chain: *dxgi.IDXGISwapChain) Error!Self {
    const vs = @embedFile("../gui/shaders/vs.hlsl");
    const ps = @embedFile("../gui/shaders/ps.hlsl");

    var device: *d3d11.ID3D11Device = undefined;

    var back_buffer: *d3d11.ID3D11Texture2D = undefined;

    var vertex_shader_blob: *d3dcommon.ID3DBlob = undefined;
    var pixel_shader_blob: *d3dcommon.ID3DBlob = undefined;

    try swap_chain.GetDevice(d3d11.ID3D11Device.UUID, @ptrCast(&device));

    const device_context = device.GetImmediateContext();
    errdefer device_context.Release();

    var result = Self{
        .device = device,
        .device_context = device_context,
        .target_window = (try swap_chain.GetDesc()).OutputWindow,
        .render_target_view = undefined,
        .vertex_shader = undefined,
        .pixel_shader = undefined,
        .blend_state = undefined,
        .input_layout = undefined,
        .constant_buffer = undefined,
        .vertex_buffer = undefined,
        .index_buffer = undefined,
        .sampler = undefined,
        .white_pixel_texture = undefined,
        .white_pixel_resource = undefined,
    };

    try swap_chain.GetBuffer(0, d3d11.ID3D11Texture2D.UUID, @ptrCast(&back_buffer));
    defer back_buffer.Release();

    try device.CreateRenderTargetView(@ptrCast(back_buffer), null, &result.render_target_view);
    errdefer result.render_target_view.Release();

    const hr_a = d3dcompiler.D3DCompile(vs.ptr, vs.len, null, null, null, "VS", "vs_5_0", 0, 0, &vertex_shader_blob, null);
    switch (d3d11.D3D11_ERROR_CODE(hr_a)) {
        .S_OK => {},
        else => |err| return d3d11.unexpectedError(err),
    }
    defer vertex_shader_blob.Release();

    const hr_b = d3dcompiler.D3DCompile(ps.ptr, ps.len, null, null, null, "PS", "ps_5_0", 0, 0, &pixel_shader_blob, null);
    switch (d3d11.D3D11_ERROR_CODE(hr_b)) {
        .S_OK => {},
        else => |err| return d3d11.unexpectedError(err),
    }
    defer pixel_shader_blob.Release();

    var blend_desc = std.mem.zeroes(d3d11.D3D11_BLEND_DESC);
    blend_desc.AlphaToCoverageEnable = windows.FALSE;
    blend_desc.RenderTarget[0].BlendEnable = windows.TRUE;
    blend_desc.RenderTarget[0].SrcBlend = d3d11.D3D11_BLEND_SRC_ALPHA;
    blend_desc.RenderTarget[0].DestBlend = d3d11.D3D11_BLEND_INV_SRC_ALPHA;
    blend_desc.RenderTarget[0].BlendOp = d3d11.D3D11_BLEND_OP_ADD;
    blend_desc.RenderTarget[0].SrcBlendAlpha = d3d11.D3D11_BLEND_ONE;
    blend_desc.RenderTarget[0].DestBlendAlpha = d3d11.D3D11_BLEND_INV_SRC_ALPHA;
    blend_desc.RenderTarget[0].BlendOpAlpha = d3d11.D3D11_BLEND_OP_ADD;
    blend_desc.RenderTarget[0].RenderTargetWriteMask = d3d11.D3D11_COLOR_WRITE_ENABLE_ALL;

    try device.CreateBlendState(&blend_desc, &result.blend_state);
    errdefer result.blend_state.Release();

    try device.CreateVertexShader(vertex_shader_blob.slice(), null, &result.vertex_shader);
    errdefer result.vertex_shader.Release();

    try device.CreatePixelShader(pixel_shader_blob.slice(), null, &result.pixel_shader);
    errdefer result.pixel_shader.Release();

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

    try device.CreateInputLayout(input_elements, vertex_shader_blob.slice(), &result.input_layout);
    errdefer result.input_layout.Release();

    var constant_buffer_desc = mem.zeroes(d3d11.D3D11_BUFFER_DESC);
    constant_buffer_desc.Usage = d3d11.D3D11_USAGE_DYNAMIC;
    constant_buffer_desc.CPUAccessFlags = d3d11.D3D11_CPU_ACCESS_WRITE;
    constant_buffer_desc.ByteWidth = @sizeOf(shared.ConstantBuffer);
    constant_buffer_desc.BindFlags = d3d11.D3D11_BIND_CONSTANT_BUFFER;

    try device.CreateBuffer(&constant_buffer_desc, null, &result.constant_buffer);
    errdefer result.constant_buffer.Release();

    var vertex_buffer_desc = mem.zeroes(d3d11.D3D11_BUFFER_DESC);
    vertex_buffer_desc.Usage = d3d11.D3D11_USAGE_DYNAMIC;
    vertex_buffer_desc.CPUAccessFlags = d3d11.D3D11_CPU_ACCESS_WRITE;
    vertex_buffer_desc.ByteWidth = shared.max_verticies * @sizeOf(shared.DrawVertex);
    vertex_buffer_desc.BindFlags = d3d11.D3D11_BIND_VERTEX_BUFFER;

    try device.CreateBuffer(&vertex_buffer_desc, null, &result.vertex_buffer);
    errdefer result.vertex_buffer.Release();

    var index_buffer_desc = mem.zeroes(d3d11.D3D11_BUFFER_DESC);
    index_buffer_desc.Usage = d3d11.D3D11_USAGE_DYNAMIC;
    index_buffer_desc.CPUAccessFlags = d3d11.D3D11_CPU_ACCESS_WRITE;
    index_buffer_desc.ByteWidth = shared.max_indicies * @sizeOf(shared.DrawIndex);
    index_buffer_desc.BindFlags = d3d11.D3D11_BIND_INDEX_BUFFER;

    try device.CreateBuffer(&index_buffer_desc, null, &result.index_buffer);
    errdefer result.index_buffer.Release();

    var texture_desc = mem.zeroes(d3d11.D3D11_TEXTURE2D_DESC);
    texture_desc.Width = 1;
    texture_desc.Height = 1;
    texture_desc.MipLevels = 1;
    texture_desc.ArraySize = 1;
    texture_desc.Format = dxgi.DXGI_FORMAT_R8_UNORM;
    texture_desc.SampleDesc.Count = 1;
    texture_desc.Usage = d3d11.D3D11_USAGE_DEFAULT;
    texture_desc.BindFlags = d3d11.D3D11_BIND_SHADER_RESOURCE;

    var initial_data = mem.zeroes(d3d11.D3D11_SUBRESOURCE_DATA);
    initial_data.pSysMem = &[1]u8{0xFF};
    initial_data.SysMemPitch = 1;

    try device.CreateTexture2D(&texture_desc, &initial_data, &result.white_pixel_texture);
    errdefer result.white_pixel_texture.Release();

    try device.CreateShaderResourceView(@ptrCast(result.white_pixel_texture), null, &result.white_pixel_resource);
    errdefer result.white_pixel_resource.Release();

    var sampler_desc = mem.zeroes(d3d11.D3D11_SAMPLER_DESC);
    sampler_desc.Filter = d3d11.D3D11_FILTER_MIN_MAG_MIP_LINEAR;
    sampler_desc.AddressU = d3d11.D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler_desc.AddressV = d3d11.D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler_desc.AddressW = d3d11.D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler_desc.MipLODBias = 0.0;
    sampler_desc.ComparisonFunc = d3d11.D3D11_COMPARISON_ALWAYS;
    sampler_desc.MinLOD = 0.0;
    sampler_desc.MaxLOD = 0.0;

    try device.CreateSamplerState(&sampler_desc, &result.sampler);
    errdefer result.sampler.Release();

    return result;
}

pub fn backend(self: *Self) Backend {
    return .{
        .ptr = self,
        .vtable = &D3D11Backend.vtable,
    };
}

const D3D11Backend = struct {
    pub const vtable = Backend.VTable{
        .deinit = &D3D11Backend.deinit,
        .frame = &D3D11Backend.frame,
        .loadImage = &D3D11Backend.loadImage,
    };

    fn deinit(context: *const anyopaque) void {
        const self: *const Self = @ptrCast(@alignCast(context));

        self.white_pixel_resource.Release();
        self.white_pixel_texture.Release();

        self.sampler.Release();

        self.blend_state.Release();
        self.input_layout.Release();

        self.constant_buffer.Release();
        self.vertex_buffer.Release();
        self.index_buffer.Release();

        self.vertex_shader.Release();
        self.pixel_shader.Release();

        self.render_target_view.Release();

        self.device_context.Release();
        self.device.Release();
    }

    fn frame(
        context: *const anyopaque,
        verticies: []const shared.DrawVertex,
        indecies: []const shared.DrawIndex,
        draw_commands: []const shared.DrawCommand,
    ) Backend.Error!void {
        const self: *const Self = @ptrCast(@alignCast(context));

        var backup_state = DeviceContextState{};
        storeState(self.device_context, &backup_state);
        defer loadState(self.device_context, &backup_state);

        {
            const rect = try windows.GetWindowRect(self.target_window);

            const width: f32 = @floatFromInt(rect.right - rect.left);
            const height: f32 = @floatFromInt(rect.bottom - rect.top);

            var mapped_resource: d3d11.D3D11_MAPPED_SUBRESOURCE = undefined;

            try self.device_context.Map(@ptrCast(self.constant_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &mapped_resource);
            defer self.device_context.Unmap(@ptrCast(self.constant_buffer), 0);

            const constant_buffer: *shared.ConstantBuffer = @ptrCast(@alignCast(mapped_resource.pData));

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

            try self.device_context.Map(@ptrCast(self.vertex_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &vertex_resource);
            defer self.device_context.Unmap(@ptrCast(self.vertex_buffer), 0);

            try self.device_context.Map(@ptrCast(self.index_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &index_resource);
            defer self.device_context.Unmap(@ptrCast(self.index_buffer), 0);

            vertex_resource.write(shared.DrawVertex, verticies, shared.max_verticies * @sizeOf(shared.DrawVertex));
            index_resource.write(shared.DrawIndex, indecies, shared.max_indicies * @sizeOf(shared.DrawIndex));
        }

        var offset: windows.UINT = 0;
        var stride: windows.UINT = @sizeOf(shared.DrawVertex);

        self.device_context.OMSetRenderTargets((&self.render_target_view)[0..1], null);
        self.device_context.OMSetBlendState(self.blend_state, &.{ 0.0, 0.0, 0.0, 0.0 }, 0xFFFFFFFF);

        self.device_context.IASetInputLayout(self.input_layout);
        self.device_context.IASetVertexBuffers(0, (&self.vertex_buffer)[0..1], (&stride)[0..1], (&offset)[0..1]);
        self.device_context.IASetIndexBuffer(self.index_buffer, if (shared.DrawIndex == u16) dxgi.DXGI_FORMAT_R16_UINT else @compileError("no corresponding DXGI_FORMAT"), 0);
        self.device_context.VSSetConstantBuffers(0, (&self.constant_buffer)[0..1]);
        self.device_context.IASetPrimitiveTopology(d3d11.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        self.device_context.VSSetShader(self.vertex_shader, null);
        self.device_context.PSSetShader(self.pixel_shader, null);
        self.device_context.PSSetSamplers(0, (&self.sampler)[0..1]);

        var index_off: windows.UINT = 0;
        for (draw_commands) |cmd| {
            const srv = blk: {
                //if (cmd.image) |img| {
                //const d3d11_image: *const D3D11Image = @ptrCast(@alignCast(img.ptr));
                //break :blk d3d11_image.resource;
                //}

                break :blk self.white_pixel_resource;
            };

            self.device_context.PSSetShaderResources(0, (&srv)[0..1]);
            self.device_context.DrawIndexed(@intCast(cmd.index_len), index_off, 0);

            index_off += @intCast(cmd.index_len);
        }
    }
};

fn storeState(context: *d3d11.ID3D11DeviceContext, state: *DeviceContextState) void {
    state.scissor_rects_len = d3d11.D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
    state.viewports_len = d3d11.D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
    state.pixel_shader_ins_len = 256;
    state.vertex_shader_ins_len = 256;
    state.geometry_shader_ins_len = 256;

    context.RSGetScissorRects(&state.scissor_rects_len, &state.scissor_rects);
    context.RSGetViewports(&state.viewports_len, &state.viewports);
    context.RSGetState(&state.rasterizer_state);
    context.OMGetBlendState(&state.blend_state, &state.blend_factor, &state.sample_mask);
    context.OMGetRenderTargets((&state.render_target_view)[0..1], &state.depth_stencil_view);
    context.OMGetDepthStencilState(&state.depth_stencil_state, &state.stencil_ref);
    context.PSGetShaderResources(0, (&state.shader_resource_view)[0..1]);
    context.PSGetSamplers(0, (&state.sampler_state)[0..1]);
    context.PSGetShader(&state.pixel_shader, &state.pixel_shader_ins, &state.pixel_shader_ins_len);
    context.VSGetShader(&state.vertex_shader, &state.vertex_shader_ins, &state.vertex_shader_ins_len);
    context.GSGetShader(&state.geometry_shader, &state.geometry_shader_ins, &state.geometry_shader_ins_len);
    context.VSGetConstantBuffers(0, (&state.constant_buf)[0..1]);
    context.IAGetPrimitiveTopology(&state.primative_topology);
    context.IAGetIndexBuffer(&state.index_buf, &state.index_buf_format, &state.index_buf_offset);
    context.IAGetVertexBuffers(0, (&state.vertex_buf)[0..1], (&state.vertex_buf_stride)[0..1], (&state.index_buf_offset)[0..1]);
    context.IAGetInputLayout(&state.input_layout);
}

fn loadState(context: *d3d11.ID3D11DeviceContext, state: *DeviceContextState) void {
    defer releaseState(state);

    // RSSetScissorRects
    context.RSSetViewports(state.viewports[0..state.viewports_len]);
    // RSSetScissorRects
    context.OMSetBlendState(state.blend_state, &state.blend_factor, state.sample_mask);
    context.OMSetRenderTargets((&state.render_target_view)[0..1], state.depth_stencil_view);
    // OMSetDepthStencilState
    context.PSSetShaderResources(0, (&state.shader_resource_view)[0..1]);
    context.PSSetSamplers(0, (&state.sampler_state)[0..1]);
    context.PSSetShader(state.pixel_shader, state.pixel_shader_ins[0..state.pixel_shader_ins_len]);
    context.VSSetShader(state.vertex_shader, state.vertex_shader_ins[0..state.vertex_shader_ins_len]);
    // GSSetShader
    context.IASetPrimitiveTopology(state.primative_topology);
    context.IASetIndexBuffer(state.index_buf, state.index_buf_format, state.index_buf_offset);
    context.IASetVertexBuffers(0, (&state.vertex_buf)[0..1], (&state.vertex_buf_stride)[0..1], (&state.vertex_buf_offset)[0..1]);
    context.VSSetConstantBuffers(0, (&state.constant_buf)[0..1]);
    context.IASetInputLayout(state.input_layout);
}

fn releaseState(state: *DeviceContextState) void {
    const release = struct {
        fn inner(mb_ctx: ?*anyopaque) void {
            if (mb_ctx) |ctx| {
                const iunknown: *windows.IUnknown = @ptrCast(@alignCast(ctx));
                iunknown.Release();
            }
        }
    }.inner;

    release(state.rasterizer_state);
    release(state.blend_state);
    release(state.render_target_view);
    release(state.depth_stencil_view);
    release(state.depth_stencil_state);
    release(state.shader_resource_view);
    release(state.sampler_state);

    release(state.pixel_shader);
    for (0..state.pixel_shader_ins_len) |i| {
        state.pixel_shader_ins[i].Release();
    }

    release(state.vertex_shader);
    for (0..state.vertex_shader_ins_len) |i| {
        state.vertex_shader_ins[i].Release();
    }

    release(state.geometry_shader);
    for (0..state.geometry_shader_ins_len) |i| {
        state.geometry_shader_ins[i].Release();
    }

    release(state.index_buf);
    release(state.vertex_buf);
    release(state.constant_buf);
    release(state.input_layout);

    state.* = undefined;
}
