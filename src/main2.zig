const Gui = @import("Gui2.zig");

pub fn setup() !void {
}

pub fn cleanup() void {
}

// now how can we make images indipendent?
// so same rendering code would work for d3d11, opengl, vulkan
pub fn render(gui: *Gui) void {
    const pos = &[2]f32{ 24.0, 24.0 };

    const image_size = 64.0;
    const padding = 16.0;

    const width = 198.0;

    const x = 0;
    const y = 1;

    // background
    gui.rect(.{ -1.0 + pos[x], -1.0 + pos[y] }, .{ pos[x] + image_size + padding + width + padding + 1.0, pos[y] + image_size + 1.0 }, 0x202E36FF);
    gui.rect(.{ pos[x], pos[y] }, .{ pos[x] + image_size + padding + width + padding, pos[y] + image_size }, 0x10191EFF);
}
