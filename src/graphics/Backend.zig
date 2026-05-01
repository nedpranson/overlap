const Backend = @This();

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
