// const c = @cImport({
//     @cInclude("onecore.h");
// });

const oc_16p16 = i32;
const oc_26p6 = i32;

const oc_open_params = extern struct {
    face_index: u32,
    desired_size: i32,
    dpi: c_short,
};

const oc_error = enum(c_uint) {
    oc_error_ok = 0,
    oc_error_invalid_param,
    oc_error_table_missing,
    oc_error_out_of_memory,
    oc_error_failed_to_open,
    oc_error_insufficient_buffer,
};

const oc_library = extern struct {
    internals: *anyopaque,
};

const oc_face = extern struct {
    internals: *anyopaque,
    metrics: oc_font_metrics,
};

const oc_size = extern struct {
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

const oc_glyph_metrics = extern struct {
    width: oc_26p6,
    height: oc_26p6,
    bearing_x: oc_26p6,
    bearing_y: oc_26p6,
    advance: oc_26p6,
};

pub extern fn oc_open_face(
    library: oc_library,
    path: [*:0]const u8,
    pparams: *const oc_open_params,
    pface: *oc_face,
) callconv(.c) oc_error;

pub extern fn oc_free_face(face: oc_face) void;

pub extern fn oc_get_glyph_metrics(
    face: oc_face,
    glyph_index: u16,
    flags: u32,
    pmetrics: *oc_glyph_metrics
) callconv(.c) void;

pub extern fn oc_render_glyph(
    face: oc_face,
    glyph_index: u16,
    psize: *oc_size,
    buffer: [*]u8,
    buffer_size: usize,
) oc_error;
