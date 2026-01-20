const std = @import("std");
const Image = @import("../Image.zig");
const Device = @import("../d3d11.zig").Device;

const Allocator = std.mem.Allocator;

gpa: Allocator,
pixels: []u8,

interface: Image,

const Static = @This();

pub fn init(gpa: Allocator, d: Image.Descriptor) Allocator.Error!*Image {
    var static = try gpa.create(Static);
    errdefer gpa.destroy(static);

    const pixels = try gpa.dupe(u8, d.data);
    errdefer gpa.free(pixels);

    static.* = .{
        .gpa = gpa,
        .pixels = pixels,
        .interface = .{
            .width = d.width,
            .height = d.height,
            .format = d.format,
            .vtable = &.{
                .destroy = destroy,
                .update = update,
                .load_resource = loadResource,
            },
        },
    };

    return &static.interface;
}

fn destroy(img: *Image) void {
    const static: *Static = @alignCast(@fieldParentPtr("interface", img));

    static.gpa.free(static.pixels);
    static.gpa.destroy(static);

    static.* = undefined;
}

fn update(img: *Image, data: []const u8) void {
    _ = img;
    _ = data;
    @panic("update called on a static image");
}

fn loadResource(img: *Image, device: *Device) Image.Resource {
    const static: *Static = @alignCast(@fieldParentPtr("interface", img));

    const tex, const srv = device.loadImage(.{
        .width = img.width,
        .height = img.height,
        .bytes = static.pixels,
        .is_static = true,
        .channels = @intFromEnum(img.format),
    });

    return .{
        .tex = tex,
        .srv = srv,
    };
}
