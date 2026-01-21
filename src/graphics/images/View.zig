const std = @import("std");
const Image = @import("../Image.zig");
const Device = @import("../d3d11.zig").Device;

pixels: [*]const u8,
interface: Image,

const View = @This();

pub fn init(d: Image.Descriptor) View {
    return .{
        .pixels = d.data.ptr,
        .interface = .{
            .width = d.width,
            .height = d.height,
            .format = d.format,
            .vtable = &.{
                .destroy = destroy,
                .update = update,
                .load_resource = loadResource,
                .sync_resource = syncResource,
            },
        },
    };
}

fn destroy(_: *Image) void {}

fn update(img: *Image, pixels: []const u8) void {
    _ = img;
    _ = pixels;
    @panic("update called on a static image");
}

fn loadResource(img: *Image, device: *Device) Device.Error!Image.Resource {
    const view: *View = @alignCast(@fieldParentPtr("interface", img));

    const tex, const srv = try device.loadImage(.{
        .width = img.width,
        .height = img.height,
        .bytes = view.pixels,
        .is_static = true,
        .channels = @intFromEnum(img.format),
    });

    return .{
        .tex = tex,
        .srv = srv,
        .revision = 0,
    };
}

fn syncResource(_: *Image, _: *Device, _: *Image.Resource) Device.Error!void {}
