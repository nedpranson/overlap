const Backend = @This();

const std = @import("std");
const windows = @import("../../windows.zig");
const gfx = @import("../../graphics.zig");

const d3d11 = windows.d3d11;

device: *d3d11.ID3D11Device,
context: *d3d11.ID3D11DeviceContext,

interface: gfx.Backend,

pub fn init(device: *d3d11.ID3D11Device) Backend {
    const context = device.GetImmediateContext();

    return .{
        .device = device,
        .context = context,
        .interface = .{ 
            .vtable = &.{
                .draw = draw,
            },
        },
    };
}

pub fn deinit(b: *Backend) void {
    b.context.Release();
    b.device.Release();
    b.* = undefined;
}

fn draw(gfx_backend: *gfx.Backend) gfx.Backend.DrawError!void {
    const b: *Backend = @alignCast(@fieldParentPtr("interface", gfx_backend));

    std.debug.print("{}\n", .{b});
}
