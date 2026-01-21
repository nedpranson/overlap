const std = @import("std");
const Image = @import("../Image.zig");
const Device = @import("../d3d11.zig").Device;

const Thread = std.Thread;
const Allocator = std.mem.Allocator;

gpa: Allocator,
lock: Thread.Mutex,

pixels: [*]u8,
revision: u32,

interface: Image,

const Dynamic = @This();

pub fn init(gpa: Allocator, d: Image.Descriptor) Allocator.Error!*Image {
    var dynamic = try gpa.create(Dynamic);
    errdefer gpa.destroy(dynamic);

    const pixels = try gpa.dupe(u8, d.data);
    errdefer gpa.free(pixels);

    dynamic.* = .{
        .gpa = gpa,
        .lock = .{},
        .pixels = pixels.ptr,
        .revision = 0,
        .interface = .{
            .width = d.width,
            .height = d.height,
            .format = d.format,
            .vtable = &.{
                .destroy = destroy,
                .update = update,
                .sync_resource = syncResource,
                .load_resource = loadResource,
            },
        },
    };

    return &dynamic.interface;
}

fn destroy(img: *Image) void {
    const dynamic: *Dynamic = @alignCast(@fieldParentPtr("interface", img));

    std.debug.print("destroying dynamic image: {*}\n", .{dynamic});

    dynamic.gpa.free(dynamic.pixels[0..img.width * img.height * @intFromEnum(img.format)]);
    dynamic.gpa.destroy(dynamic);
}

fn update(img: *Image, pixels: []const u8) void {
    const dynamic: *Dynamic = @alignCast(@fieldParentPtr("interface", img));

    dynamic.lock.lock();
    defer dynamic.lock.unlock();

    @memcpy(dynamic.pixels[0..img.width * img.height * @intFromEnum(img.format)], pixels);
    dynamic.revision +%= 1;
}

fn syncResource(img: *Image, device: *Device, cache: *Image.Resource) void {
    const dynamic: *Dynamic = @alignCast(@fieldParentPtr("interface", img));

    dynamic.lock.lock();
    defer dynamic.lock.unlock();

    if (cache.revision == dynamic.revision) {
        return;
    }

    std.debug.print("updating backend image!\n", .{});

    device.updateImage(@ptrCast(@alignCast(cache.tex)), .{
        .width = img.width,
        .height = img.height,
        .bytes = dynamic.pixels,
        .is_static = false,
        .channels = @intFromEnum(img.format),
    });
    cache.revision = dynamic.revision;
}

fn loadResource(img: *Image, device: *Device) Image.Resource {
    const dynamic: *Dynamic = @alignCast(@fieldParentPtr("interface", img));

    dynamic.lock.lock();
    defer dynamic.lock.unlock();

    const tex, const srv = device.loadImage(.{
        .width = img.width,
        .height = img.height,
        .bytes = dynamic.pixels,
        .is_static = false,
        .channels = @intFromEnum(img.format),
    });

    return .{
        .tex = tex,
        .srv = srv,
        .revision = dynamic.revision,
    };
}
