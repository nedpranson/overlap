const std = @import("std");
const shared = @import("gui/shared.zig");
const Image = @import("graphics/Image.zig");

const Gui = @This();

const x = 0;
const y = 1;

const white_pixel: Image = .{
    .width = 1,
    .height = 1,
    .data = &.{0xFF},
    .format = .r,
    .id = 0,
};

draw_commands: std.ArrayList(shared.DrawCommand),

draw_verticies: std.ArrayList(shared.DrawVertex),
draw_indecies: std.ArrayList(shared.DrawIndex),

pub fn init(draw_commands: []shared.DrawCommand, draw_verticies: []shared.DrawVertex, draw_indecies: []shared.DrawIndex) Gui {
    return .{
        .draw_commands = .initBuffer(draw_commands),
        .draw_verticies = .initBuffer(draw_verticies),
        .draw_indecies = .initBuffer(draw_indecies),
    };
}

pub fn rect(gui: *Gui, top: [2]f32, bot: [2]f32, col: u32) void {
    const verticies = [4]shared.DrawVertex{
        .{ .pos = .{ top[x], top[y] }, .uv = .{ 0.0, 0.0 }, .col = col },
        .{ .pos = .{ bot[x], top[y] }, .uv = .{ 1.0, 0.0 }, .col = col },
        .{ .pos = .{ bot[x], bot[y] }, .uv = .{ 1.0, 1.0 }, .col = col },
        .{ .pos = .{ top[x], bot[y] }, .uv = .{ 0.0, 1.0 }, .col = col },
    };

    const indecies = [_]u16{
        0, 1, 2,
        0, 2, 3,
    };

    gui.addDrawCommand(.{
        .verticies = &verticies,
        .indecies = &indecies,
    });
}

pub fn image(gui: *Gui, top: [2]f32, bot: [2]f32, img: Image) void {
    const flags: u8 = @intFromEnum(img.format);
    const verticies = [4]shared.DrawVertex{
        .{ .pos = .{ top[x], top[y] }, .uv = .{ 0.0, 0.0 }, .col = 0xFFFFFFFF, .flags = flags },
        .{ .pos = .{ bot[x], top[y] }, .uv = .{ 1.0, 0.0 }, .col = 0xFFFFFFFF, .flags = flags },
        .{ .pos = .{ bot[x], bot[y] }, .uv = .{ 1.0, 1.0 }, .col = 0xFFFFFFFF, .flags = flags },
        .{ .pos = .{ top[x], bot[y] }, .uv = .{ 0.0, 1.0 }, .col = 0xFFFFFFFF, .flags = flags },
    };

    const indecies = [_]u16{
        0, 1, 2,
        0, 2, 3,
    };

    gui.addDrawCommand(.{
        .image = img,
        .verticies = &verticies,
        .indecies = &indecies,
    });
}

const DrawCommand = struct {
    verticies: []const shared.DrawVertex,
    indecies: []const u16,
    image: Image = white_pixel,
};

// todo: on debug we can check if indecie are like in bounds
fn addDrawCommand(self: *Gui, draw_cmd: DrawCommand) void {
    const amt: shared.DrawIndex = @intCast(self.draw_verticies.items.len);

    if (self.draw_verticies.items.len + draw_cmd.verticies.len > self.draw_verticies.capacity) return;
    if (self.draw_indecies.items.len + draw_cmd.indecies.len > self.draw_indecies.capacity) return;

    //self.draw_verticies.ensureUnusedCapacity(draw_cmd.verticies.len) catch return;
    //self.draw_indecies.ensureUnusedCapacity(draw_cmd.indecies.len) catch return;

    const reuse_image = blk: {
        const last_draw_cmd = self.draw_commands.getLastOrNull() orelse break :blk false;
        break :blk last_draw_cmd.image_id == draw_cmd.image.id;
    };

    if (!reuse_image) {
        if (self.draw_commands.items.len == self.draw_commands.capacity) return;
        // self.validate_image(draw_cmd.image);
    }

    self.draw_verticies.appendSliceAssumeCapacity(draw_cmd.verticies);

    for (draw_cmd.indecies) |idx| {
        // todo: update base idx at render call
        self.draw_indecies.appendAssumeCapacity(amt + idx);
    }

    if (reuse_image) {
        const last_draw_cmd = &self.draw_commands.items[self.draw_commands.items.len - 1];
        last_draw_cmd.index_len += @intCast(draw_cmd.indecies.len);

        return;
    }

    self.draw_commands.appendAssumeCapacity(.{
        .image_id = draw_cmd.image.id,
        .index_len = @intCast(draw_cmd.indecies.len),
    });
}
