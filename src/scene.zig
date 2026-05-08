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
    gs.rect(.{ 0.0, 0.0 }, .{ 130.0, 130.0 }, 0x808080FF);
    gs.image(.{ 30.0, 30.0 }, .{ 100.0, 100.0 }, s.image);
}
