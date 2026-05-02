// pub const Device = @import("graphics/Device.zig");
// pub const d3d11 = @import("graphics/d3d11.zig");

pub const max_draw_commands = 128;
pub const max_verticies = max_draw_commands * 4;
pub const max_indicies = max_draw_commands * 6;

pub const d3d11 = struct {
    pub const Backend = @import("graphics/backends/D3D11.zig");
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

pub const Backend = struct {
    vtable: *const VTable,

    pub const VTable = struct {
        draw: *const fn (b: *Backend) DrawError!void,
    };

    pub const DrawError = error{
        DrawFailed,
    };

    pub inline fn draw(b: *Backend) DrawError!void {
        return b.vtable.draw(b);
    }
};

