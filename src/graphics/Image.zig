const std = @import("std");
const hooks = @import("../hooks.zig");

const assert = std.debug.assert;
const atomic = std.atomic;
const math = std.math;

const Image = @This();

pub const Format = enum(u4) {
    r = 1,
    rgba = 4,
};

pub const Usage = enum(u4) {
    static,
    dynamic,
};

width: u32,
height: u32,

data: [*]const u8,

id: u32,
modified: u16 = 0,

format: Format,

pub const Desc = struct {
    width: u32,
    height: u32,
    data: []const u8,
    format: Format,
    usage: Usage = .static,
};

pub fn init(desc: Desc) Image {
    assert(math.mulWide(u32, desc.width, desc.height) * @intFromEnum(desc.format) == desc.data.len);

    return .{
        .width = desc.width,
        .height = desc.height,
        .data = desc.data.ptr,
        .format = desc.format,
        .id = generate_id(),
        .modified = if (desc.usage == .dynamic) 1 else 0, // 0 suppose to mean that this image will never be modified
    };
}

pub fn deinit(img: Image) void {
    for (hooks.hooks) |hook| {
        hook.uload_image(img.id);
    }
}

pub fn update(img: *Image, data: []const u8) void {
    assert(math.mulWide(u32, img.width, img.height) * @intFromEnum(img.format) == data.len);
    assert(img.modified > 0);

    // todo: no thread safety here!!!!
    img.data = data.ptr;
    img.modified +%= 1;
}

fn generate_id() u32 {
    const static = struct {
        // set to one as zero is 1x1 white image pixel id (default)
        var id: atomic.Value(u32) = .init(1);
    };

    return static.id.fetchAdd(1, .monotonic);
}
