const std = @import("std");
const windows = @import("../windows.zig");
const shared = @import("shared.zig");
const Image = @import("Image.zig");

const mem = std.mem;
const dxgi = windows.dxgi;
const d3d11 = windows.d3d11;
const d3dcommon = windows.d3dcommon;
const d3dcompiler = windows.d3dcompiler;

// todo: brong back Backend interface oop is not that bad as it seems
//       guess there is a reason why the world is built on it

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

pub const Device = struct {
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

    pub const Error = error{
        OutOfMemory,
        Unexpected,
    };

    pub fn init(swap_chain: *dxgi.IDXGISwapChain) Error!Device {
        const vs = @embedFile("shaders/vs.hlsl");
        const ps = @embedFile("shaders/ps.hlsl");

        var device: *d3d11.ID3D11Device = undefined;

        var back_buffer: *d3d11.ID3D11Texture2D = undefined;

        var vertex_shader_blob: *d3dcommon.ID3DBlob = undefined;
        var pixel_shader_blob: *d3dcommon.ID3DBlob = undefined;

        try swap_chain.GetDevice(d3d11.ID3D11Device.UUID, @ptrCast(&device));

        const device_context = device.GetImmediateContext();
        errdefer device_context.Release();

        var result = Device{
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
            //.white_pixel_texture = undefined,
            //.white_pixel_resource = undefined,
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

        //var texture_desc = mem.zeroes(d3d11.D3D11_TEXTURE2D_DESC);
        //texture_desc.Width = 1;
        //texture_desc.Height = 1;
        //texture_desc.MipLevels = 1;
        //texture_desc.ArraySize = 1;
        //texture_desc.Format = dxgi.DXGI_FORMAT_R8_UNORM;
        //texture_desc.SampleDesc.Count = 1;
        //texture_desc.Usage = d3d11.D3D11_USAGE_DEFAULT;
        //texture_desc.BindFlags = d3d11.D3D11_BIND_SHADER_RESOURCE;

        // todo no!
        //var initial_data = mem.zeroes(d3d11.D3D11_SUBRESOURCE_DATA);
        //initial_data.pSysMem = &[1]u8{0xFF};
        //initial_data.SysMemPitch = 1;

        //try device.CreateTexture2D(&texture_desc, &initial_data, &result.white_pixel_texture);
        //errdefer result.white_pixel_texture.Release();

        //try device.CreateShaderResourceView(@ptrCast(result.white_pixel_texture), null, &result.white_pixel_resource);
        //errdefer result.white_pixel_resource.Release();

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

    pub fn deinit(device: *Device) void {
        //device.white_pixel_resource.Release();
        //device.white_pixel_texture.Release();

        device.sampler.Release();

        device.blend_state.Release();
        device.input_layout.Release();

        device.constant_buffer.Release();
        device.vertex_buffer.Release();
        device.index_buffer.Release();

        device.vertex_shader.Release();
        device.pixel_shader.Release();

        device.render_target_view.Release();

        device.device_context.Release();
        device.device.Release();

        device.* = undefined;
    }

    pub fn render(
        device: *Device,
        verticies: []const shared.DrawVertex,
        indecies: []const shared.DrawIndex,
        draw_commands: []const shared.DrawCommand,
        load_srv: *const fn (device: *Device, img: *Image) *anyopaque,
    ) Error!void {
        var backup_state = DeviceContextState{};
        storeState(device.device_context, &backup_state);
        defer loadState(device.device_context, &backup_state);

        {
            const rect = try windows.GetWindowRect(device.target_window);

            const width: f32 = @floatFromInt(rect.right - rect.left);
            const height: f32 = @floatFromInt(rect.bottom - rect.top);

            var mapped_resource: d3d11.D3D11_MAPPED_SUBRESOURCE = undefined;

            try device.device_context.Map(@ptrCast(device.constant_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &mapped_resource);
            defer device.device_context.Unmap(@ptrCast(device.constant_buffer), 0);

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

            try device.device_context.Map(@ptrCast(device.vertex_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &vertex_resource);
            defer device.device_context.Unmap(@ptrCast(device.vertex_buffer), 0);

            try device.device_context.Map(@ptrCast(device.index_buffer), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &index_resource);
            defer device.device_context.Unmap(@ptrCast(device.index_buffer), 0);

            vertex_resource.write(shared.DrawVertex, verticies, shared.max_verticies * @sizeOf(shared.DrawVertex));
            index_resource.write(shared.DrawIndex, indecies, shared.max_indicies * @sizeOf(shared.DrawIndex));
        }

        var offset: windows.UINT = 0;
        var stride: windows.UINT = @sizeOf(shared.DrawVertex);

        device.device_context.OMSetRenderTargets((&device.render_target_view)[0..1], null);
        device.device_context.OMSetBlendState(device.blend_state, &.{ 0.0, 0.0, 0.0, 0.0 }, 0xFFFFFFFF);

        device.device_context.IASetInputLayout(device.input_layout);
        device.device_context.IASetVertexBuffers(0, (&device.vertex_buffer)[0..1], (&stride)[0..1], (&offset)[0..1]);
        device.device_context.IASetIndexBuffer(device.index_buffer, if (shared.DrawIndex == u16) dxgi.DXGI_FORMAT_R16_UINT else @compileError("no corresponding DXGI_FORMAT"), 0);
        device.device_context.VSSetConstantBuffers(0, (&device.constant_buffer)[0..1]);
        device.device_context.IASetPrimitiveTopology(d3d11.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        device.device_context.VSSetShader(device.vertex_shader, null);
        device.device_context.PSSetShader(device.pixel_shader, null);
        device.device_context.PSSetSamplers(0, (&device.sampler)[0..1]);

        //var white_pixel_tex: *d3d11.ID3D11Texture2D = undefined;
        //var white_pixel_srv: *d3d11.ID3D11ShaderResourceView = undefined;

        //var texture_desc = mem.zeroes(d3d11.D3D11_TEXTURE2D_DESC);
        //texture_desc.Width = 1;
        //texture_desc.Height = 1;
        //texture_desc.MipLevels = 1;
        //texture_desc.ArraySize = 1;
        //texture_desc.Format = dxgi.DXGI_FORMAT_R8_UNORM;
        //texture_desc.SampleDesc.Count = 1;
        //texture_desc.Usage = d3d11.D3D11_USAGE_DEFAULT;
        //texture_desc.BindFlags = d3d11.D3D11_BIND_SHADER_RESOURCE;

        //var initial_data = mem.zeroes(d3d11.D3D11_SUBRESOURCE_DATA);
        //initial_data.pSysMem = &[1]u8{0xFF};
        //initial_data.SysMemPitch = 1;

        //try device.device.CreateTexture2D(&texture_desc, &initial_data, &white_pixel_tex);
        //defer white_pixel_tex.Release();

        //try device.device.CreateShaderResourceView(@ptrCast(white_pixel_tex), null, &white_pixel_srv);
        //defer white_pixel_srv.Release();

        var index_off: windows.UINT = 0;
        for (draw_commands) |cmd| {
            const srv: *d3d11.ID3D11ShaderResourceView = @ptrCast(@alignCast(load_srv(device, cmd.image)));
            defer cmd.image.remRef();

            device.device_context.PSSetShaderResources(0, (&srv)[0..1]);
            device.device_context.DrawIndexed(@intCast(cmd.index_len), index_off, 0); // todo: use third argument

            index_off += @intCast(cmd.index_len);
        }
    }

    pub const Descriptor = struct {
        width: u32,
        height: u32,

        bytes: [*]const u8,

        is_static: bool,
        channels: u3,
    };

    pub fn loadImage(device: *Device, d: Descriptor) struct { *d3d11.ID3D11Texture2D, *d3d11.ID3D11ShaderResourceView } {
        var tex: *d3d11.ID3D11Texture2D = undefined;
        var srv: *d3d11.ID3D11ShaderResourceView = undefined;

        const format: windows.INT = switch (d.channels) {
            1 => dxgi.DXGI_FORMAT_R8_UNORM,
            4 => dxgi.DXGI_FORMAT_R8G8B8A8_UNORM,
            else => unreachable,
        };

        const usage: windows.INT = if (d.is_static) d3d11.D3D11_USAGE_DEFAULT else d3d11.D3D11_USAGE_DYNAMIC;
        const cpu_flags: windows.UINT = if (d.is_static) 0 else d3d11.D3D11_CPU_ACCESS_WRITE;

        var texture_desc = mem.zeroes(d3d11.D3D11_TEXTURE2D_DESC);
        texture_desc.Width = d.width;
        texture_desc.Height = d.height;
        texture_desc.MipLevels = 1;
        texture_desc.ArraySize = 1;
        texture_desc.Format = format;
        texture_desc.SampleDesc.Count = 1;
        texture_desc.Usage = usage;
        texture_desc.BindFlags = d3d11.D3D11_BIND_SHADER_RESOURCE;
        texture_desc.CPUAccessFlags = cpu_flags;

        if (d.is_static) {
            var initial_data = mem.zeroes(d3d11.D3D11_SUBRESOURCE_DATA);
            initial_data.pSysMem = d.bytes;
            initial_data.SysMemPitch = d.width * d.channels;

            // todo: handle err
            device.device.CreateTexture2D(&texture_desc, &initial_data, &tex) catch unreachable;
            errdefer tex.Release();
        } else {
            // todo: handle err
            device.device.CreateTexture2D(&texture_desc, null, &tex) catch unreachable;
            errdefer tex.Release();

            var mapped_resource: d3d11.D3D11_MAPPED_SUBRESOURCE = undefined;

            // todo: handle err
            device.device_context.Map(@ptrCast(tex), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &mapped_resource) catch unreachable;
            defer device.device_context.Unmap(@ptrCast(tex), 0);

            mapped_resource.write(u8, d.bytes[0..d.width * d.height * d.channels], d.width * d.channels);
            errdefer tex.Release();
        }
        errdefer tex.Release();

        // todo: handle
        device.device.CreateShaderResourceView(@ptrCast(tex), null, &srv) catch unreachable;
        errdefer srv.Release();

        return .{ tex, srv };
    }

    pub fn updateImage(device: *Device, tex: *d3d11.ID3D11Texture2D, d: Descriptor) void {
        var mapped_resource: d3d11.D3D11_MAPPED_SUBRESOURCE = undefined;

        // todo: catch errors
        device.device_context.Map(@ptrCast(tex), 0, d3d11.D3D11_MAP_WRITE_DISCARD, 0, &mapped_resource) catch unreachable;
        defer device.device_context.Unmap(@ptrCast(tex), 0);

        mapped_resource.write(u8, d.bytes[0..d.width * d.height * d.channels], d.width * d.channels);
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
