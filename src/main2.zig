const std = @import("std");
const windows = @import("windows.zig");
const Gui = @import("Gui2.zig");

const Allocator = std.mem.Allocator;

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
var manager: windows.GlobalSystemMediaTransportControlsSessionManager = undefined;

pub fn setup() !void {
    const allocator = gpa.allocator();

    try windows.RoInitialize(windows.RO_INIT_MULTITHREADED);
    errdefer windows.RoUninitialize();

    manager = try (try windows.GlobalSystemMediaTransportControlsSessionManager.RequestAsync()).getAndForget(allocator);
    errdefer manager.Release();

    try sessionChanged({}, manager);
    _ = try manager.CurrentSessionChanged(allocator, {}, sessionChanged);
}

pub fn cleanup() void {
    // free that id only then release

    manager.Release();
    windows.RoUninitialize();

    _ = gpa.deinit();
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

pub fn sessionChanged(_: void, _: windows.GlobalSystemMediaTransportControlsSessionManager) !void {
    std.log.info("Session changed", .{});
}
