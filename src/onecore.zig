const c = @cImport({
    @cInclude("onecore.h");
});

const oc_16p16 = i32;
const oc_26p6 = i32;

const oc_open_params = extern struct {
    face_index: u32 = 0,
    desired_size: oc_26p6 = 12 << 6,
    dpi: c_short = 96,
};

const oc_error = enum(c_uint) {
    oc_error_ok = 0,
    oc_error_invalid_param,
    oc_error_table_missing,
    oc_error_out_of_memory,
    oc_error_failed_to_open,
    oc_error_insufficient_buffer,
};

const oc_load_flags = packed struct(u32) {
    LOAD_NO_SCALE: bool = false,
    _pad: u31 = 0,
};

pub const oc_library = extern struct {
    internals: *anyopaque,
};

pub const oc_face = extern struct {
    internals: *anyopaque,
    metrics: oc_font_metrics,
};

pub const oc_size = extern struct {
    rows: u32,
    cols: u32,
};

const oc_font_metrics = extern struct {
    upem: u16,
    ppem: u16,
    scale: oc_26p6,
    ascent: u16,
    descent: u16,
    leading: i16,
    underline_position: i16,
    underline_thickness: u16,
};

pub const oc_glyph_metrics = extern struct {
    width: oc_26p6,
    height: oc_26p6,
    bearing_x: oc_26p6,
    bearing_y: oc_26p6,
    advance: oc_26p6,
};

const abi = struct {
    extern fn oc_init_library(plibrary: *oc_library) oc_error;

    extern fn oc_free_library(library: oc_library) void;

    extern fn oc_open_face(
        library: oc_library,
        path: [*:0]const u8,
        pparams: *const oc_open_params,
        pface: *oc_face,
    ) callconv(.c) oc_error;

    extern fn oc_free_face(face: oc_face) callconv(.c) void;

    extern fn oc_get_char_index(face: oc_face, charcode: u32) u16;

    extern fn oc_get_glyph_metrics(
        face: oc_face,
        glyph_index: u16,
        flags: oc_load_flags,
        pmetrics: *oc_glyph_metrics
    ) callconv(.c) void;

    extern fn oc_render_glyph(
        face: oc_face,
        glyph_index: u16,
        psize: *oc_size,
        buffer: ?[*]u8,
        buffer_size: usize,
    ) callconv(.c) oc_error;
};

pub const OCInitLibraryError = error{
    OutOfMemory,
    Unexpected,
};

pub fn oc_init_library() OCInitLibraryError!oc_library {
    var library: oc_library = undefined;
    return switch (abi.oc_init_library(&library)) {
        .oc_error_ok => library,
        .oc_error_out_of_memory => error.OutOfMemory,
        else => error.Unexpected,
    };
}

pub const oc_free_library = abi.oc_free_library;

pub const OCOpenFaceError = error{
    OutOfMemory,
    Unexpected,
};

pub fn oc_open_face(library: oc_library, path: [:0]const u8, params: oc_open_params) OCOpenFaceError!oc_face {
    var face: oc_face = undefined;
    return switch (abi.oc_open_face(library, path, &params, &face)) {
        .oc_error_ok => face,
        .oc_error_out_of_memory => error.OutOfMemory,
        else => error.Unexpected,
    };
}

pub const oc_free_face = abi.oc_free_face;

pub fn oc_get_char_index(face: oc_face, charcode: u21) ?u16 {
    const idx = abi.oc_get_char_index(face, charcode);
    return if (idx == 0) null else idx;
}

pub fn oc_get_glyph_metrics(face: oc_face, glyph_index: u16, flags: oc_load_flags) oc_glyph_metrics {
    var metrics: oc_glyph_metrics = undefined;
    abi.oc_get_glyph_metrics(face, glyph_index, flags, &metrics);
    return metrics;
}

pub const OCRenderGlyphError = error{
    OutOfMemory,
    Unexpected,
};

pub fn oc_render_glyph(face: oc_face, glyph_index: u16, buffer: ?[]u8) OCRenderGlyphError!oc_size {
    var size: oc_size = undefined;
    return switch (abi.oc_render_glyph(face, glyph_index, &size, if (buffer) |b| b.ptr else null, if (buffer) |b| b.len else 0)) {
        .oc_error_ok => size,
        .oc_error_out_of_memory => error.OutOfMemory,
        else => error.Unexpected,
    };
}
