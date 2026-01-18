const std = @import("std");
const Image = @import("Image.zig");
const heap = std.heap;
const math = std.math;

// todo: add tests as im clueless

const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

allocator: Allocator,

image: *Image,

data: []u8,
size: u32,

skylines: std.DoublyLinkedList,
skylines_pool: heap.MemoryPoolExtra(Skyline, .{ .growable = true }),

const Atlas = @This();

const Skyline = struct {
    x: u32,
    y: u32,
    width: u32,

    node: std.DoublyLinkedList.Node = .{},
};

const Region = struct {
    x: u32,
    y: u32,

    width: u32,
    height: u32,
};

// todo: we need to allow growing it

pub fn init(allocator: Allocator, size: u32) !Atlas {
    const data = try allocator.alloc(u8, size * size);
    errdefer allocator.free(data);

    var self: Atlas = .{
        .allocator = allocator,
        .image = try .init(allocator, .{
            .width = size,
            .height = size,
            .data = data,
            .format = .r,
            .usage = .dynamic,
        }),
        .data = data,
        .size = size,
        .skylines = .{},
        .skylines_pool = .init(allocator),
    };
    errdefer self.deinit();

    try self.skylines_pool.preheat(64);
    self.clear();

    return self;
}

pub fn deinit(self: *Atlas) void {
    self.image.deinit();
    self.allocator.free(self.data);
    self.skylines_pool.deinit();

    self.* = undefined;
}

pub fn clear(self: *Atlas) void {
    @memset(self.data, 0);

    self.image.update(self.data);
    _ = self.skylines_pool.reset(.retain_capacity);

    self.skylines = .{};

    var skyline = self.skylines_pool.create() catch unreachable;
    skyline.* = .{
        .x = 0,
        .y = 0,

        .width = self.size,
    };

    self.skylines.prepend(&skyline.node);
}

pub fn fill(self: *Atlas, region: Region, data: []u8) void {
    assert(data.len == region.width * region.height);
    assert(self.image.width > region.x);
    assert(self.image.height > region.y);

    for (0..region.height) |y| {
        const src_i = y * region.width;
        const dst_i = (y + region.y) * self.size + region.x;

        @memcpy(self.data[dst_i .. dst_i + region.width], data[src_i .. src_i + region.width]);
    }

    self.image.update(self.data);
}

pub fn reserve(
    self: *Atlas,
    width: u32,
    height: u32,
) !Region {
    var region: Region = .{ .x = 0, .y = 0, .width = width, .height = height };

    const best_skyline = blk: {
        var best_width: u32 = math.maxInt(u32);
        var best_height: u32 = math.maxInt(u32);

        var selected: ?*Skyline = null;

        var curr = self.skylines.first;
        while (curr) |node| {
            defer curr = node.next;

            const skyline: *Skyline = @fieldParentPtr("node", node);
            const y = self.baseline(skyline, width, height) orelse continue;

            if (y + height < best_height or (y + height == best_height and skyline.width < best_width)) {
                selected = skyline;
                best_width = skyline.width;
                best_height = y + height;

                region.x = skyline.x;
                region.y = y;
            }
        }

        break :blk selected orelse return error.NoSpaceLeft;
    };

    const new_skyline = try self.skylines_pool.create();
    new_skyline.* = .{
        .x = region.x,
        .y = region.y + region.height,
        .width = region.width,
    };

    self.skylines.insertBefore(&best_skyline.node, &new_skyline.node);

    var prev = &new_skyline.node;
    var curr: ?*std.DoublyLinkedList.Node = &best_skyline.node;

    // loop till we're inside
    while (curr) |node| {
        const skyline: *Skyline = @fieldParentPtr("node", node);
        const prev_skyline: *Skyline = @fieldParentPtr("node", prev);

        // inside
        if (prev_skyline.x + prev_skyline.width > skyline.x) {
            const move = prev_skyline.x + prev_skyline.width - skyline.x;

            skyline.x += move;
            skyline.width -|= move;

            if (skyline.width == 0) {
                curr = node.next;

                self.skylines.remove(node);
                self.skylines_pool.destroy(skyline);

                continue;
            }

            prev = node;
            curr = node.next;

            continue;
        }
        break;
    }

    if (new_skyline.node.next) |nn| {
        self.merge(&new_skyline.node, nn);
    }

    if (new_skyline.node.prev) |pp| {
        self.merge(pp, &new_skyline.node);
    }

    return region;
}

fn merge(self: *Atlas, left: *std.DoublyLinkedList.Node, right: *std.DoublyLinkedList.Node) void {
    const left_skyline: *Skyline = @fieldParentPtr("node", left);
    const right_skyline: *Skyline = @fieldParentPtr("node", right);

    if (left_skyline.y == right_skyline.y) {
        @branchHint(.cold);

        left_skyline.width += right_skyline.width;

        self.skylines.remove(right);
        self.skylines_pool.destroy(right_skyline);
    }
}

fn baseline(
    self: Atlas,
    skyline: *Skyline,
    width: u32,
    height: u32,
) ?u32 {
    if (skyline.x + width > self.size) {
        return null;
    }

    var y = skyline.y;
    var width_left = width;

    var curr: ?*std.DoublyLinkedList.Node = &skyline.node;
    while (width_left > 0) {
        defer curr = curr.?.next;
        const curr_skyline: *Skyline = @fieldParentPtr("node", curr.?);

        if (curr_skyline.y + height > self.size) {
            return null;
        }

        y = @max(y, curr_skyline.y);
        width_left -|= curr_skyline.width;
    }

    return y;
}
