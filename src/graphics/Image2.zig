const std = @import("std");
const hooks = @import("../hooks.zig");

const atomic = std.atomic;
const Allocator = std.mem.Allocator;
const math = std.math;
const Mutex = std.Thread.Mutex;
const assert = std.debug.assert;

// we need to make images
// inside memory
// todo: make image on the heap and only clean it self when ref is at 0
// todo: make image data on heap too!
// todo: add ref counting so we would know when it is safe to free
// make uuid be a pointer

const Image = @This();

pub const Format = enum(u4) {
    r = 1,
    rgba = 4,
};

pub const Usage = enum(u1) {
    static,
    dynamic,
};

width: u32,
height: u32,

data: [*]const u8, // can change if dynamic
modified: atomic.Value(u16), // can change if dynamic

id: u32,

format: Format,
usage: Usage,

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
        .modified = .init(0),
        .usage = desc.usage,
    };
}

pub fn deinit(img: Image) void {
    for (hooks.hooks) |hook| {
        hook.uload_image(img.id);
    }
}

pub fn update(img: *Image, data: []const u8) void {
    assert(math.mulWide(u32, img.width, img.height) * @intFromEnum(img.format) == data.len);

    img.data = data.ptr;
    _ = img.modified.fetchAdd(1, .release);
}

// Thread-safe
fn generate_id() u32 {
    const static = struct {
        // set to one as zero is 1x1 white image pixel id (default)
        var id: atomic.Value(u32) = .init(1);
    };

    return static.id.fetchAdd(1, .monotonic);
}
