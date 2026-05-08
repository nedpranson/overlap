// pub const Device = @import("graphics/Device.zig");
// pub const d3d11 = @import("graphics/d3d11.zig");
pub const Surface = @import("Surface.zig");

pub const max_draw_commands = 128;
pub const max_verticies = max_draw_commands * 4;
pub const max_indicies = max_draw_commands * 6;

pub const d3d11 = struct {
    pub const Backend = @import("graphics/backends/D3D11.zig");
};

pub const Viewport = struct {
    width: u32,
    height: u32,

    pub const unset = Viewport{
        .width = 0,
        .height = 0,
    };
};

pub const DrawCommand = struct {
    srv: *anyopaque,
    index_len: DrawIndex,
    base_vertex: DrawIndex,
};

pub const DrawIndex = u16;

pub const ConstantBuffer = extern struct {
    mvp: [4][4]f32,
};

pub const DrawVertex = extern struct {
    pos: [2]f32,
    uv: [2]f32,
    col: u32,
    flags: u8 = 1,
};

pub const Image = struct {
    tex: *anyopaque,
    srv: *anyopaque,

    deinit: *const fn (i: Image) void
};

pub const Backend = struct {
    viewport: Viewport,
    identity: Image,

    vtable: *const VTable,

    pub const VTable = struct {
        draw: *const fn (b: *Backend, surface: *const Surface) void,
        image: *const fn (b: *Backend, desc: ImageDesc) error{OutOfMemory}!Image,
        // reset: *const fn (b: *Backend) error{OutOfMemory}!void
    };

    pub const ImageDesc = struct {
        data: [*]const u8,
        width: u32,
        height: u32,
        dynamic: bool = false,
    };
};
