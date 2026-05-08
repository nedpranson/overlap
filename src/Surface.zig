const Surface = @This();

const std = @import("std");
const gfx = @import("graphics.zig");

const unicode = std.unicode;

const x = 0;
const y = 1;

const DrawCommand = struct {
    verticies: []const gfx.DrawVertex,
    indecies: []const gfx.DrawIndex,
    image: *const gfx.Image,
};

draw_commands: std.ArrayList(gfx.DrawCommand),

draw_verticies: std.ArrayList(gfx.DrawVertex),
draw_indecies: std.ArrayList(gfx.DrawIndex),

identity: *const gfx.Image,

pub fn rect(gui: *Surface, top: [2]f32, bot: [2]f32, col: u32) void {
    const verticies = [4]gfx.DrawVertex{
        .{ .pos = .{ top[x], top[y] }, .uv = .{ 0.0, 0.0 }, .col = col },
        .{ .pos = .{ bot[x], top[y] }, .uv = .{ 1.0, 0.0 }, .col = col },
        .{ .pos = .{ bot[x], bot[y] }, .uv = .{ 1.0, 1.0 }, .col = col },
        .{ .pos = .{ top[x], bot[y] }, .uv = .{ 0.0, 1.0 }, .col = col },
    };

    const indecies = [6]u16{
        0, 1, 2,
        0, 2, 3,
    };

    addDrawCommand(gui, .{
        .verticies = &verticies,
        .indecies = &indecies,
        .image = gui.identity,
    });
}

pub fn image(gui: *Surface, top: [2]f32, bot: [2]f32, img: gfx.Image) void {
    const verticies = [4]gfx.DrawVertex{
        .{ .pos = .{ top[x], top[y] }, .uv = .{ 0.0, 0.0 }, .col = 0xFFFFFFFF },
        .{ .pos = .{ bot[x], top[y] }, .uv = .{ 1.0, 0.0 }, .col = 0xFFFFFFFF },
        .{ .pos = .{ bot[x], bot[y] }, .uv = .{ 1.0, 1.0 }, .col = 0xFFFFFFFF },
        .{ .pos = .{ top[x], bot[y] }, .uv = .{ 0.0, 1.0 }, .col = 0xFFFFFFFF },
    };

    const indecies = [6]u16{
        0, 1, 2,
        0, 2, 3,
    };

    addDrawCommand(gui, .{
        .verticies = &verticies,
        .indecies = &indecies,
        .image = &img,
    });
}

fn addDrawCommand(self: *Surface, draw_cmd: DrawCommand) void {
    const base_vertex: gfx.DrawIndex = @intCast(self.draw_verticies.items.len);

    if (self.draw_verticies.items.len + draw_cmd.verticies.len > self.draw_verticies.capacity) return;
    if (self.draw_indecies.items.len + draw_cmd.indecies.len > self.draw_indecies.capacity) return;
    if (self.draw_commands.items.len == self.draw_commands.capacity) return;

    self.draw_verticies.appendSliceAssumeCapacity(draw_cmd.verticies);
    self.draw_indecies.appendSliceAssumeCapacity(draw_cmd.indecies);

    self.draw_commands.appendAssumeCapacity(.{
        .image = draw_cmd.image,
        .index_len = @intCast(draw_cmd.indecies.len),
        .base_vertex = base_vertex,
    });
}
