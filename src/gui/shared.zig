const Image = @import("Image.zig");

// how many quads we can draw
pub const max_draw_commands = 128;
pub const max_verticies = max_draw_commands * 4;
pub const max_indicies = max_draw_commands * 6;

pub const DrawIndex = u16;

pub const DrawCommand = struct {
    image_id: u32,
    index_len: DrawIndex,
};

pub const DrawVertex = extern struct {
    pos: [2]f32,
    uv: [2]f32,
    col: u32,
    flags: u8 = 1,
};

pub const ConstantBuffer = extern struct {
    mvp: [4][4]f32,
};

pub const Input = struct {
    mouse_x: i16 = 0,
    mouse_y: i16 = 0,

    mouse_ldown: bool = false,
    mouse_rdown: bool = false,
};
