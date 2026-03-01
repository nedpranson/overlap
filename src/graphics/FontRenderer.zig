const std = @import("std");
const onecore = @import("../onecore.zig");
// todo: when onecore is complete use that
// todo: add text shaping too
// todo: colored fonts!!!
// const fat = @import("fat");
const Atlas = @import("Atlas.zig");

const Allocator = std.mem.Allocator;
const Thread = std.Thread;

// todo: make FontRenderer threadsafe!!!

// allocator: Allocator,
//
// atlas: Atlas,
//
// glyphs: std.AutoHashMapUnmanaged(Descriptor, Glyph),
// fonts: std.ArrayListUnmanaged(fat.Face),
//
pub const Glyph = struct {
    uv0: [2]f32,
    uv1: [2]f32,

    width: u32,
    height: u32,

    metrics: onecore.oc_glyph_metrics,
};
//
// pub const Descriptor = struct {
//     codepoint: u21,
//     size: u32,
//     // size, weight, slant
// };

allocator: Allocator,
lock: Thread.Mutex,

glyphs: std.AutoHashMapUnmanaged(u21, Glyph),

library: onecore.oc_library,
face: onecore.oc_face,

atlas: Atlas,

const FontRenderer = @This();

pub fn init(allocator: Allocator) !FontRenderer {
    const library = try onecore.oc_init_library();
    errdefer onecore.oc_free_library(library);

    const face = try onecore.oc_open_face(library, "", .{});
    errdefer onecore.oc_free_face(face);

    return .{
        .allocator = allocator,
        .lock = .{},
        .glyphs = .empty,
        .library = library,
        .face = face,
        .atlas = try Atlas.init(allocator, 512),
    };
    // return .{
    //     .allocator = allocator,
    //     .atlas = try Atlas.init(allocator, 512),
    //     .glyphs = .empty,
    //     .fonts = .empty,
    // };
}

pub fn deinit(self: *FontRenderer) void {
    // todo: pass allocator here!!!!
    self.atlas.deinit();
    self.glyphs.deinit(self.allocator);

    onecore.oc_free_face(self.face);
    onecore.oc_free_library(self.library);


//     for (self.fonts.items) |font| {
//         font.close();
//     }
//
//     self.fonts.deinit(self.allocator);
//     self.glyphs.deinit(self.allocator);
//     self.atlas.deinit();
}

pub fn getGlyph(self: *FontRenderer, codepoint: u21) !Glyph {//, descriptor: Descriptor) !Glyph {
    self.lock.lock();
    defer self.lock.unlock();

    const gop = try self.glyphs.getOrPut(self.allocator, codepoint);
    if (!gop.found_existing) blk: {
        const index = onecore.oc_get_char_index(self.face, codepoint).?;
        const metrics = onecore.oc_get_glyph_metrics(self.face, index, .{});

        const size = try onecore.oc_render_glyph(self.face, index, null);
        if (size.rows == 0 or size.cols == 0) {
            @branchHint(.unlikely);

            gop.value_ptr.* = .{
                .uv0 = .{ 0.0, 0.0 },
                .uv1 = .{ 0.0, 0.0 },
                .width = 0,
                .height = 0,
                .metrics = metrics,
            };

            break :blk;
        }

        const rect = try self.atlas.reserve(size.cols, size.rows);

        // todo: think of some ways directly copying the data with pitches
        //       enable it in onecore
        const bitmap = try self.allocator.alloc(u8, size.rows * size.cols);
        defer self.allocator.free(bitmap);

        _ = try onecore.oc_render_glyph(self.face, index, bitmap);
        self.atlas.fill(rect, bitmap);

        const altas_size: f32 = @floatFromInt(self.atlas.size);

        gop.value_ptr.* = .{
            .uv0 = .{ @as(f32, @floatFromInt(rect.x)) / altas_size, @as(f32, @floatFromInt(rect.y)) / altas_size },
            .uv1 = .{ @as(f32, @floatFromInt(rect.x + size.cols)) / altas_size, @as(f32, @floatFromInt(rect.y + size.rows)) / altas_size },
            .width = size.cols,
            .height = size.rows,
            .metrics = metrics,
        };
    }

    return gop.value_ptr.*;
    

    // if (self.glyphs.get(descriptor)) |glyph| {
    //     return glyph;
    // }
    //
    // // idk render a square if null
    // const font = (try getFont(self, descriptor)) orelse @panic("not implemented");
    // // todo: fix space char as some weird shit happens when passing it
    // const idx = font.glyphIndex(descriptor.codepoint).?;
    //
    // const render = try font.renderGlyph(self.allocator, idx);
    // defer render.deinit(self.allocator);
    //
    // if (render.width == 0 or render.height == 0) {
    //     const glyph: Glyph = .{
    //         .uv0 = .{ 0.0, 0.0 },
    //         .uv1 = .{ 0.0, 0.0 },
    //         .width = 0,
    //         .height = 0,
    //         .metrics = try font.glyphMetrics(idx),
    //     };
    //
    //     try self.glyphs.put(self.allocator, descriptor, glyph);
    //
    //     return glyph;
    // }
    //
    // const rect = try self.atlas.reserve(render.width, render.height);
    // self.atlas.fill(rect, render.bitmap);
    //
    // const altas_size: f32 = @floatFromInt(self.atlas.size);
    // const glyph: Glyph = .{
    //     .uv0 = .{ @as(f32, @floatFromInt(rect.x)) / altas_size, @as(f32, @floatFromInt(rect.y)) / altas_size },
    //     .uv1 = .{ @as(f32, @floatFromInt(rect.x + render.width)) / altas_size, @as(f32, @floatFromInt(rect.y + render.height)) / altas_size },
    //     .width = render.width,
    //     .height = render.height,
    //     .metrics = try font.glyphMetrics(idx),
    // };
    //
    // try self.glyphs.put(self.allocator, descriptor, glyph);
    //
    // return glyph;
}

// fn getFont(self: *FontRenderer, descriptor: Descriptor) !?fat.Face {
//     for (self.fonts.items) |*font| {
//         if (font.glyphIndex(descriptor.codepoint) != null) {
//             try font.setSize(.{ .points = @bitCast(descriptor.size) });
//             return font.*;
//         }
//     }
//
//     var it = try fat.iterateFonts(self.allocator, .{ .family = "Segoe UI", .codepoint = descriptor.codepoint });
//     defer it.deinit();
//
//     while (try it.next()) |deffered_face| {
//         defer deffered_face.deinit();
//
//         if (!deffered_face.hasCodepoint(descriptor.codepoint)) {
//             continue;
//         }
//
//         try self.fonts.append(self.allocator, try deffered_face.open(.{ .size = .{ .points = @bitCast(descriptor.size) } }));
//         return self.fonts.getLast();
//     }
//
//     return null;
// }
