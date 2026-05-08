const Scene = @This();

const std = @import("std");
const gfx = @import("graphics.zig");

image: gfx.Image,

pub fn init(b: *gfx.Backend) !Scene {
    return .{
        .image = try b.vtable.image(b, .{
            .data = &.{0xFF, 0x00, 0x00, 0xFF},
            .width = 2,
            .height = 2,
        }),
    };
}

pub fn deinit(s: *Scene) void {
    s.image.deinit(s.image);
}

pub fn frame(s: *Scene, gs: *gfx.Surface) void {
    gs.image(.{ 0.0, 0.0 }, .{ 100.0, 100.0 }, s.image);
}
