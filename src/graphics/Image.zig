const std = @import("std");
const atomic = std.atomic;

const Image = @This();

fn generate_id() u32 {
    const static = struct {
        var id: atomic.Value(u32) = .init(0);
    };

    return static.id.fetchAdd(1, .unordered);
}

width: u32,
height: u32,

data: [*]const u8,
id: u32,

pub fn init() !Image {
    return .{
        .id = generate_id(),
    };
}

pub fn deinit() void {
    // broadcast that image with id was destroyed
}
