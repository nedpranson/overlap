const std = @import("std");
const math = std.math;
const atomic = std.atomic;

const Allocator = std.mem.Allocator;
const Thread = std.Thread;
const assert = std.debug.assert;

pub const Format = enum(u3) {
    r = 1,
    rgba = 4,
};

pub const Usage = enum(u1) {
    static,
    dynamic,
};

const Image = @This();

pub const Descriptor = struct {
    width: u32,
    height: u32,
    data: []const u8,
    format: Format,
    usage: Usage = .static,
};

// todo: we could make Image an interface
// that would like have Dynamic or Static variants

gpa: Allocator,

width: u32,
height: u32,

ref_count: atomic.Value(u32),

data: [*]u8,
modified: u16, // only dynamic uses this

mu: Thread.Mutex, // only dynamic uses this

format: Format,
usage: Usage,

pub fn init(gpa: Allocator, desc: Descriptor) Allocator.Error!*Image {
    assert(math.mulWide(u32, desc.width, desc.height) * @intFromEnum(desc.format) == desc.data.len);

    const copy = try gpa.dupe(u8, desc.data);
    errdefer gpa.free(copy);

    const img = try gpa.create(Image);
    errdefer gpa.destroy(img);

    img.* = .{
        .gpa = gpa,
        .width = desc.width,
        .height = desc.height,
        .ref_count = .init(1),
        .data = copy.ptr,
        .modified = 0,
        .mu = .{},
        .format = desc.format,
        .usage = desc.usage,
    };

    return img;

}

pub inline fn deinit(img: *Image) void {
    decRef(img);
}

pub fn update(img: *Image, data: []const u8) void {
    assert(math.mulWide(u32, img.width, img.height) * @intFromEnum(img.format) == data.len);

    img.mu.lock();
    defer img.mu.unlock();

    @memcpy(img.data[0..img.width * img.height], data);
    img.modified += 1;
}

pub fn addRef(img: *Image) void {
    assert(img.ref_count.fetchAdd(1, .monotonic) != 0);
}

pub fn decRef(img: *Image) void {
    const prev_count = img.ref_count.fetchSub(1, .release);
    assert(prev_count != 0);

    if (prev_count == 1) {
        _ = img.ref_count.load(.acquire);

        // todo: boadcast!
        std.debug.print("freeing the image!!\n", .{});

        img.gpa.free(img.data[0..img.width * img.height]);
        img.gpa.destroy(img);
    }
}
