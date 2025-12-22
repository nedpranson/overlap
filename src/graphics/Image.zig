const std = @import("std");

const assert = std.debug.assert;
const atomic = std.atomic;
const math = std.math;

const Image = @This();

pub const Format = enum(u4) {
    r = 1,
    rgba = 4,
};

width: u32,
height: u32,

data: [*]const u8,

id: u32,

format: Format,

pub const Desc = struct {
    width: u32,
    height: u32,
    data: []const u8,
    format: Format,
};

pub fn init(desc: Desc) Image {
    assert(math.mulWide(u32, desc.width, desc.height) * @intFromEnum(desc.format) == desc.data.len);

    return .{
        .width = desc.width,
        .height = desc.height,
        .data = desc.data.ptr,
        .format = desc.format,
        .id = generate_id(),
    };
}

pub fn deinit(img: Image) void {
    _ = img;
    // broadcast that image with id was destroyed
}

fn generate_id() u32 {
    const static = struct {
        var id: atomic.Value(u32) = .init(0);
    };

    return static.id.fetchAdd(1, .monotonic);
}
