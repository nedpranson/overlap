const std = @import("std");
const shared = @import("graphics/shared.zig");
const Image = @import("graphics/Image.zig");
const FontRenderer = @import("graphics/FontRenderer.zig");

const unicode = std.unicode;

const Gui = @This();

const x = 0;
const y = 1;

var pixel = [1]u8{0xFF};
var white_pixel: Image = .{
    .width = 1,
    .height = 1,
    .data = &pixel,
    .format = .r,
    .gpa = undefined,
    .ref_count = .init(1),
    .mu = .{},
    .modified = 0,
    .usage = .static,
};

draw_commands: std.ArrayList(shared.DrawCommand),

draw_verticies: std.ArrayList(shared.DrawVertex),
draw_indecies: std.ArrayList(shared.DrawIndex),

//font_renderer: *FontRenderer,

//ctx: *anyopaque,
//request_srv: *const fn(ctx: *anyopaque, img: *Image) *anyopaque,

pub fn init(
    draw_commands: []shared.DrawCommand,
    draw_verticies: []shared.DrawVertex,
    draw_indecies: []shared.DrawIndex,
    //font_renderer: *FontRenderer,
    //ctx: *anyopaque,
    //request_srv: *const fn(ctx: *anyopaque, img: *Image) *anyopaque,
) Gui {
    return .{
        .draw_commands = .initBuffer(draw_commands),
        .draw_verticies = .initBuffer(draw_verticies),
        .draw_indecies = .initBuffer(draw_indecies),
        //.font_renderer = font_renderer,
        //.ctx = ctx,
        //.request_srv = request_srv,
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
        //.image = gui.request_srv(gui.ctx, &white_pixel),
        .image = undefined,
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
        .image = gui.request_srv(gui.ctx, img),
    });
}

const DrawCommand = struct {
    verticies: []const shared.DrawVertex,
    indecies: []const u16,
    image: *anyopaque,
};

pub const Descriptor = struct {
    size: f32 = 16.0,
    color: u32 = 0xFFFFFFFF,
};

// text functions are not threadsafe!!!!!!!!!

// as now we're not using kerning or shaping it's all good, later if we will choose todo these stuff
// we will need to pass in a string to compite its width or some other work around
pub fn advanceWidth(self: *Gui, codepoint: u21, descriptor: Descriptor) !u32 {
    const glyph = try self.font_renderer.getGlyph(.{ .size = @bitCast(descriptor.size), .codepoint = codepoint });
    return glyph.metrics.advance_x;
}

pub fn advanceWidthf(self: *Gui, codepoint: u21, descriptor: Descriptor) !f32 {
    return @floatFromInt(try advanceWidth(self, codepoint, descriptor));
}

pub fn textW(gui: *Gui, pos: [2]f32, msg: []const u16, descriptor: Descriptor) !void {
    var it = unicode.Wtf16LeIterator.init(msg);

    var advance: f32 = 0.0;
    while (it.nextCodepoint()) |codepoint| {
        // todo: this is just stoopid that zig cant hash f32 so i need todo it my self ok
        const glyph = try gui.font_renderer.getGlyph(.{ .size = @bitCast(descriptor.size), .codepoint = codepoint });
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
            .image = gui.request_srv(gui.ctx, gui.font_renderer.atlas.image),
            .verticies = &verticies,
            .indecies = &indecies,
        });
    }
}

// todo: on debug we can check if indecie are like in bounds
fn addDrawCommand(self: *Gui, draw_cmd: DrawCommand) void {
    const amt: shared.DrawIndex = @intCast(self.draw_verticies.items.len);

    if (self.draw_verticies.items.len + draw_cmd.verticies.len > self.draw_verticies.capacity) return;
    if (self.draw_indecies.items.len + draw_cmd.indecies.len > self.draw_indecies.capacity) return;

    //self.draw_verticies.ensureUnusedCapacity(draw_cmd.verticies.len) catch return;
    //self.draw_indecies.ensureUnusedCapacity(draw_cmd.indecies.len) catch return;

    const reuse_image = blk: {
        const last_draw_cmd = self.draw_commands.getLastOrNull() orelse break :blk false;
        break :blk last_draw_cmd.srv == draw_cmd.image;
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
        .srv = draw_cmd.image,
        .index_len = @intCast(draw_cmd.indecies.len),
    });
}
