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

pub const Glyph = struct {
    uv: struct{ [2]f32, [2]f32 },
    extent: onecore.oc_extent,
    metrics: onecore.oc_glyph_metrics,
};

pub const Descriptor = struct {
    codepoint: u21,
    size: u32,
    // size, weight, slant
};

allocator: Allocator,
lock: Thread.Mutex,

glyphs: std.AutoHashMapUnmanaged(Descriptor, Glyph),
fonts: std.ArrayList(onecore.oc_face),

library: *onecore.oc_library,
collection: onecore.oc_collection,

atlas: Atlas,

const FontRenderer = @This();

pub fn init(allocator: Allocator) !FontRenderer {
    const library = try onecore.oc_init_library();
    errdefer onecore.oc_free_library(library);

    const collection = try onecore.ocf_init_collection(library);
    errdefer onecore.ocf_free_collection(&collection);

    try onecore.ocf_load_fonts(&collection);

    return .{
        .allocator = allocator,
        .lock = .{},
        .glyphs = .empty,
        .fonts = .empy,
        .library = library,
        .collection = collection,
        .atlas = try Atlas.init(allocator, 512),
    };
}

pub fn deinit(self: *FontRenderer) void {
     for (self.fonts.items) |*font| {
        onecore.ocl_free_face(font);
     }

    onecore.ocf_free_collection(&self.collection);
    onecore.oc_free_library(self.library);

    self.fonts.deinit(self.allocator);
    self.glyphs.deinit(self.allocator);
    self.atlas.deinit();
}

pub fn getGlyph(self: *FontRenderer, desc: Descriptor) !Glyph {
    self.lock.lock();
    defer self.lock.unlock();

    const gop = try self.glyphs.getOrPut(self.allocator, desc);
    if (!gop.found_existing) {
        const face = (try getFont(self, desc)).?;
        const index = onecore.ocl_get_char_index(face, desc.codepoint).?;

        var glyph: Glyph = .{
            .uv = .{ 
                .{ 0.0, 0.0 },
                .{ 0.0, 0.0 },
            },
            .extent = try onecore.ocl_render_glyph(self.face, index, null),
            .metrics = onecore.ocl_get_glyph_metrics(self.face, index, .{}),
        };

        if (glyph.extent.rows > 0 and glyph.extent.cols > 0) {
            @branchHint(.likely);

            const rect = try self.atlas.reserve(glyph.extent.cols, glyph.extent.rows);

            const bitmap = self.allocator.alloc(u8, glyph.extent.rows * glyph.extent.cols);
            defer self.allocator.free(bitmap);

            try onecore.ocl_render_glyph(self.face, index, bitmap);
            self.atlas.fill(rect, bitmap);

            glyph.uv = .{
                .{ @as(f32, @floatFromInt(rect.x)) / self.atlas.size, @as(f32, @floatFromInt(rect.y)) / self.atlas.size },
                .{ @as(f32, @floatFromInt(rect.x + glyph.extent.cols)) / self.atlas.size, @as(f32, @floatFromInt(rect.y + glyph.extent.rows)) / self.atlas.size },
            };
        }

        gop.value_ptr.* = glyph;

        // todo: think of some ways directly copying the data with pitches
        //       enable it in onecore
        // todo: think if we want dwrite to raster glyphs, they kinda look bad
        //       check if msdfgen is worth for rendering glyphs (onecore stage 2 should solve this)
        // const bitmap = try self.allocator.alloc(u8, size.rows * size.cols);
        // defer self.allocator.free(bitmap);
        //
        // _ = try onecore.oc_render_glyph(self.face, index, bitmap);
        // self.atlas.fill(rect, bitmap);
        //
        // const altas_size: f32 = @floatFromInt(self.atlas.size);
        //
        // gop.value_ptr.* = .{
        //     .uv0 = .{ @as(f32, @floatFromInt(rect.x)) / altas_size, @as(f32, @floatFromInt(rect.y)) / altas_size },
        //     .uv1 = .{ @as(f32, @floatFromInt(rect.x + size.cols)) / altas_size, @as(f32, @floatFromInt(rect.y + size.rows)) / altas_size },
        //     .width = size.cols,
        //     .height = size.rows,
        //     .metrics = metrics,
        // };
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

const FontScore = packed struct(u32) {
    segoe: bool = false,
    regular: bool = false,
    roman: bool = false,
    has_char: bool = false,

    _pad: u30 = 0,

    fn score(font: *onecore.oc_font, ch: u21) u32 {
        var s: FontScore = .{};

        s.segoe = std.mem.eql(u8, "Segoe UI", font.family);
        s.regular = font.weight == 400;
        s.roman = font.slant == .roman;
        s.has_char = onecore.ocf_has_character(font, ch);

        return @intCast(s);
    }
};

fn getFont(self: *FontRenderer, desc: Descriptor) !?*onecore.oc_face {
    std.sort.block(*onecore.oc_font, self.collection.fonts[0..self.collection.nfonts], desc.codepoint, struct {
        fn lessThan(ch: u21, a: *onecore.oc_font, b: onecore.oc_font) bool {
            return FontScore.score(a, ch) > FontScore.score(b, ch);
        }
    }.lessThan);

    const font = self.collection.fonts[0];
    if (!onecore.ocf_has_character(font, desc.codepoint)) {
        return null;
    }

    const size: onecore.oc_26p6 = @intFromFloat(@as(f32, @floatFromInt(desc.size)) * 64.0);
    const face = onecore.ocf_open_font(font, size, 0);
    _ = face;
}
