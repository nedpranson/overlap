const c = @cImport({
    @cInclude("onecore.h");
});

const oc_16p16 = i32;
const oc_26p6 = i32;

const oc_open_params = extern struct {
    face_index: u32 = 0,
    desired_size: oc_26p6 = 12 << 6,
    dpi: u16 = 72,
};

const oc_load_flags = packed struct(u32) {
    LOAD_NO_SCALE: bool = false,
    LOAD_NO_HINTING: bool = false,
    _pad1: u2 = 0,
    LOAD_NO_FITTING: bool = false,
    _pad2: u27 = 0,
};

const oc_error = enum(c_int) {
    ok,
    invalid_param,
    table_missing,
    out_of_memory,
    failed_to_open,
    insufficient_buffer,
    invalid_pixel_size,
};

const oc_slant = enum(c_int) {
    roman,
    italic,
    oblique,
};

pub const oc_library = *opaque {};

pub const oc_collection = extern struct {
    impl: *anyopaque,

    fonts: [*]*oc_font,
    nfonts: u32,
};

pub const oc_font = extern struct {
    family: [*:0]const u8,
    slant: oc_slant,
    weight: u16,
};

pub const oc_size = extern struct {
    ppem: u16,
    slant: oc_slant,
    scale: oc_16p16,
};

pub const oc_extent = extern struct {
    rows: u32,
    cols: u32,
};

pub const oc_face = extern struct {
    impl: *anyopaque,

    size: oc_size,
    upem: u16,
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
    extern fn oc_init_library(olibrary: **oc_library) callconv(.c) oc_error;

    extern fn oc_free_library(library: *oc_library) callconv(.c) void;

    extern fn ocf_init_collection(library: *const oc_library, ocollection: *oc_collection) callconv(.c) oc_error;

    extern fn ocf_free_collection(collection: *oc_collection) callconv(.c) void;

    extern fn ocf_load_fonts(collection: *oc_collection) callconv(.c) oc_error;

    extern fn ocf_has_character(font: *const oc_font, character: u32) callconv(.c) bool;

    extern fn ocf_open_font(font: *const oc_font, desired_size: oc_26p6, dpi: u16, oface: *oc_face) callconv(.c) oc_error;

    extern fn ocl_free_face(face: *oc_face) callconv(.c) void;

    extern fn ocl_get_char_index(face: *const oc_face) callconv(.c) u16;

    extern fn ocl_get_glyph_metrics(face: *const oc_face, index: u16, flags: oc_load_flags, ometrics: *oc_glyph_metrics) callconv(.c) void;
};

pub const InitLibraryError = error{
    OutOfMemory,
    Unexpected,
};

pub fn oc_init_library() InitLibraryError!*oc_library {
    var library: *oc_library = undefined;
    return switch (abi.oc_init_library(&library)) {
        .ok => library,
        .out_of_memory => error.OutOfMemory,
        else => error.Unexpected,
    };
}

pub const oc_free_library = abi.oc_free_library;

pub const InitCollectionError = error{
    OutOfMemory,
    Unexpected,
};

pub fn ocf_init_collection(library: *const oc_library) InitCollectionError!oc_collection {
    var collection: oc_collection = undefined;
    return switch (abi.ocf_init_collection(library, &collection)) {
        .ok => collection,
        .out_of_memory => error.OutOfMemory,
        else => error.Unexpected,
    };
}

pub const ocf_free_collection = abi.ocf_free_collection;

pub const LoadFontsError = error{
    OutOfMemory,
    Unexpected,
};

pub fn ocf_load_fonts(collection: *oc_collection) LoadFontsError!void {
    return switch (abi.ocf_load_fonts(collection)) {
        .ok => {},
        .out_of_memory => error.OutOfMemory,
        else => error.Unexpected,
    };
}

pub inline fn ocf_has_character(font: *const oc_font, character: u21) bool {
    return abi.ocf_has_character(font, character);
}

pub const OpenFontError = error{
    InvalidPixelSize,
    OutOfMemory,
    Unexpected,
};

pub fn ocf_open_font(font: *const oc_font, desired_size: oc_26p6, dpi: u16) OpenFontError!oc_face {
    var face: *oc_face = undefined;
    return switch (abi.ocf_open_font(font, desired_size, dpi, &face)) {
        .ok => face,
        .invalid_pixel_size => error.InvalidPixelSize,
        .out_of_memory => error.OutOfMemory,
        else => error.Unexpected,
    };
}

pub const ocl_free_face = abi.ocl_free_face;

pub fn ocl_get_char_index(face: *const oc_face) ?u16 {
    const index = abi.ocl_get_char_index(face);
    return if (index > 0) index else null;
}

pub fn ocl_get_glyph_metrics(face: *const oc_face, index: u16, flags: oc_load_flags) oc_glyph_metrics {
    var metrics: oc_glyph_metrics = undefined;
    abi.ocl_get_glyph_metrics(face, index, flags, &metrics);
    return metrics;
}
