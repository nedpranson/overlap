pub const Device = @import("graphics/Device.zig");
pub const d3d11 = @import("graphics/d3d11.zig");

pub const Backend = struct {
    vtable: *const VTable,

    pub const VTable = struct {
        draw: *const fn (b: *Backend) DrawError!void,
    };

    pub const DrawError = error{
        DrawFailed,
    };

    pub inline fn draw(b: *Backend) DrawError!void {
        return b.vtable.draw();
    }
};

