const std = @import("std");
const hooks = @import("../hooks.zig");
const Device = @import("d3d11.zig").Device;

const atomic = std.atomic;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub const Static = @import("images/Static.zig");

width: u32,
height: u32,

format: Format,

ref_count: atomic.Value(u32) = .init(1),

vtable: *const VTable,

const Image = @This();

pub const Format = enum(u3) {
    r = 1,
    rgba = 4,
};

// this is more like d3d11 thing
// opengl, and d3d9 only has texture
// it seems vulkan has 3 resources
// but hey this is irrelevant, atleast for now
pub const Resource = struct {
    tex: *anyopaque,
    srv: *anyopaque,
};

// todo: make load_resource take in like a funciton ptr
pub const VTable = struct {
    destroy: *const fn (img: *Image) void,
    update: *const fn (img: *Image, data: []const u8) void,
    load_resource: *const fn (img: *Image, device: *Device) Resource,
};

pub const Descriptor = struct {
    width: u32,
    height: u32,
    data: []const u8,
    format: Format,
};

pub fn init(gpa: Allocator, d: Descriptor) Allocator.Error!*Image {
    assert(d.data.len == d.width * d.height * @intFromEnum(d.format));
    return Static.init(gpa, d);
}

pub inline fn deinit(img: *Image) void {
    remRef(img);
}

pub inline fn update(img: *Image, data: []const u8) void {
    return img.vtable.update(img, data);
}

pub inline fn loadResource(img: *Image, device: *Device) Resource {
    return img.vtable.load_resource(img, device);
}

pub fn addRef(img: *Image) void {
    const refs = img.ref_count.fetchAdd(1, .monotonic);
    assert(refs != 0);

    std.debug.print("add ref: {d}\n", .{refs + 1});
}

pub fn remRef(img: *Image) void {
    const refs = img.ref_count.fetchSub(1, .release);
    assert(refs != 0);

    std.debug.print("rem ref: {d}\n", .{refs - 1});

    if (refs == 1) {
        _ = img.ref_count.load(.acquire);

        hooks.broadcastUnloadImage(img);
        img.vtable.destroy(img);
    }
}
