const std = @import("std");
const shared = @import("graphics/shared.zig");
const Image = @import("graphics/Image.zig");
const Device = @import("graphics/d3d11.zig").Device;

const unicode = std.unicode;

const Gui = @This();

const x = 0;
const y = 1;

var white_pixel: Image.View = .init(.{
    .width = 1,
    .height = 1,
    .data = &.{0xFF},
    .format = .r,
});

draw_commands: std.ArrayList(shared.DrawCommand),

draw_verticies: std.ArrayList(shared.DrawVertex),
draw_indecies: std.ArrayList(shared.DrawIndex),

pub fn init(
    draw_commands: []shared.DrawCommand,
    draw_verticies: []shared.DrawVertex,
    draw_indecies: []shared.DrawIndex,
) Gui {
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
        .image = &white_pixel.interface,
    });
}

pub fn image(gui: *Gui, top: [2]f32, bot: [2]f32, img: *Image) void {
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
        .verticies = &verticies,
        .indecies = &indecies,
        .image = img,
    });
}

const DrawCommand = struct {
    verticies: []const shared.DrawVertex,
    indecies: []const u16,
    image: *Image,
};

pub const Descriptor = struct {
    size: f32 = 16.0,
    color: u32 = 0xFFFFFFFF,
};

// todo: remove mutex as make FontRenderer threadsafe
//       this is just a dirty fix
var lock: std.Thread.Mutex = .{};

// text functions are not threadsafe!!!!!!!!!

// as now we're not using kerning or shaping it's all good, later if we will choose todo these stuff
// we will need to pass in a string to compite its width or some other work around
pub fn advanceWidth(_: *Gui, codepoint: u21, descriptor: Descriptor) u32 {
    _ = descriptor;
    lock.lock();
    defer lock.unlock();

    const glyph = @import("renderer.zig").font_renderer.getGlyph(codepoint) catch return 0;
    return glyph.metrics.advance_x;
}

pub fn advanceWidthf(self: *Gui, codepoint: u21, descriptor: Descriptor) f32 {
    return @floatFromInt(advanceWidth(self, codepoint, descriptor));
}

pub fn textW(gui: *Gui, pos: [2]f32, msg: []const u16, descriptor: Descriptor) void {
    var it = unicode.Wtf16LeIterator.init(msg);

    lock.lock();
    defer lock.unlock();

    var advance: f32 = 0.0;
    while (it.nextCodepoint()) |codepoint| {
        // todo: this is just stoopid that zig cant hash f32 so i need todo it my self ok
        // todo: have a fallback glyph on errors
        // todo: make FontRenderer threadsafe!!!
        const glyph = @import("renderer.zig").font_renderer.getGlyph(codepoint) catch return;
        defer advance += @floatFromInt(glyph.metrics.advance_x);

        const top = [2]f32{ pos[x] + @as(f32, @floatFromInt(glyph.metrics.bearing_x)) + advance, pos[y] + @as(f32, @floatFromInt(glyph.metrics.bearing_y)) };
        const bot = [2]f32{ top[x] + @as(f32, @floatFromInt(glyph.width)), top[y] + @as(f32, @floatFromInt(glyph.height)) };

        const verticies = [_]shared.DrawVertex{
            .{ .pos = .{ top[x], top[y] }, .uv = .{ glyph.uv0[x], glyph.uv0[y] }, .col = descriptor.color, .flags = 5 },
            .{ .pos = .{ bot[x], top[y] }, .uv = .{ glyph.uv1[x], glyph.uv0[y] }, .col = descriptor.color, .flags = 5 },
            .{ .pos = .{ bot[x], bot[y] }, .uv = .{ glyph.uv1[x], glyph.uv1[y] }, .col = descriptor.color, .flags = 5 },
            .{ .pos = .{ top[x], bot[y] }, .uv = .{ glyph.uv0[x], glyph.uv1[y] }, .col = descriptor.color, .flags = 5 },
        };

        const indecies = [_]u16{
            0, 1, 2,
            0, 2, 3,
        };

        gui.addDrawCommand(.{
            .image = @import("renderer.zig").font_renderer.atlas.image,
            .verticies = &verticies,
            .indecies = &indecies,
        });
    }
}

fn addDrawCommand(self: *Gui, draw_cmd: DrawCommand) void {
    const base_vertex: shared.DrawIndex = @intCast(self.draw_verticies.items.len);

    if (self.draw_verticies.items.len + draw_cmd.verticies.len > self.draw_verticies.capacity) return;
    if (self.draw_indecies.items.len + draw_cmd.indecies.len > self.draw_indecies.capacity) return;
    if (self.draw_commands.items.len == self.draw_commands.capacity) return;

    self.draw_verticies.appendSliceAssumeCapacity(draw_cmd.verticies);
    self.draw_indecies.appendSliceAssumeCapacity(draw_cmd.indecies);

    // need to add ref to prevent image from disapearing
    // rendering backend (like d3d11) will be responsible to releasing this added ref
    draw_cmd.image.addRef();

    self.draw_commands.appendAssumeCapacity(.{
        .image = draw_cmd.image,
        .index_len = @intCast(draw_cmd.indecies.len),
        .base_vertex = base_vertex,
    });
}
