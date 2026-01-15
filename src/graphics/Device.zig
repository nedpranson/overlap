const std = @import("std");
const shared = @import("shared.zig");

const Allocator = std.mem.Allocator;
const Device = @This();

vtable: *const VTable,

pub const Error = error{
    OutOfMemory,
    Unexpected,
};

pub const VTable = struct {
    deinit: *const fn (*Device) void,
    present: *const fn (*Device, verticies: []const shared.DrawVertex, indecies: []const u16, draw_commands: []const shared.DrawCommand) Error!void,
};

pub fn deinit(d: *Device) void {
    d.vtable.deinit(d);
}

pub fn render(
    d: *Device,
    verticies: []const shared.DrawVertex,
    indecies: []const shared.DrawIndex,
    draw_commands: []const shared.DrawCommand,
) Error!void {
    return d.vtable.render(d, verticies, indecies, draw_commands);
}
