const std = @import("std");
const windows = @import("windows.zig");
const Gui = @import("Gui2.zig");

const Allocator = std.mem.Allocator;
const Thread = std.Thread;

const Context = struct {
    mutex: Thread.Mutex = .{},

    session: ?windows.GlobalSystemMediaTransportControlsSession = null,

    timeline: struct {
        last_updated: i64 = 0,
        end_time: i64 = 0,
        position: i64 = 0,
    } = .{},
};

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;

var manager: windows.GlobalSystemMediaTransportControlsSessionManager = undefined;
var context: Context = .{};

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

    if (context.session) |session| {
        session.Release();
    }

    manager.Release();
    windows.RoUninitialize();

    _ = gpa.deinit();
}

// now how can we make images indipendent?
// so same rendering code would work for d3d11, opengl, vulkan
pub fn render(gui: *Gui) void {
    const session = blk: {
        context.mutex.lock();
        defer context.mutex.unlock();

        break :blk context.session orelse return;
    };

    const pos = &[2]f32{ 24.0, 24.0 };

    const image_size = 64.0;
    const padding = 16.0;

    const width = 198.0;

    const x = 0;
    const y = 1;

    // background
    gui.rect(.{ -1.0 + pos[x], -1.0 + pos[y] }, .{ pos[x] + image_size + padding + width + padding + 1.0, pos[y] + image_size + 1.0 }, 0x202E36FF);
    gui.rect(.{ pos[x], pos[y] }, .{ pos[x] + image_size + padding + width + padding, pos[y] + image_size }, 0x10191EFF);

    const progress = blk: {
        context.mutex.lock();
        defer context.mutex.unlock();

        // !!!
        const playback_info = session.GetPlaybackInfo() catch unreachable;
        defer playback_info.Release();

        if (playback_info.PlaybackStatus() != .Playing) {
            break :blk context.timeline.position;
        }

        const timestamp = std.time.milliTimestamp();
        const elapsed = timestamp - context.timeline.last_updated;

        break :blk context.timeline.position + elapsed;
    };

    const bar_max_width = image_size + padding + width + padding + 2.0;
    const bar_width = @min(@as(f32, @floatFromInt(progress)) / @as(f32, @floatFromInt(context.timeline.end_time)), 1.0) * bar_max_width;

    // progress bar
    gui.rect(.{ -1.0 + pos[x], pos[y] + image_size }, .{ -1.0 + pos[x] + bar_width, pos[y] + image_size + 1.0 }, 0x00DFA2FF);
}

pub fn sessionChanged(_: void, _: windows.GlobalSystemMediaTransportControlsSessionManager) !void {
    const session = blk: {
        context.mutex.lock();
        defer context.mutex.unlock();

        if (context.session) |session| {
            session.Release();
            context.session = null;
        }

        context.session = try manager.GetCurrentSession();
        break :blk context.session.?;
    };

    try timelineChanged({}, session);

    _ = try session.TimelinePropertiesChanged(gpa.allocator(), {}, timelineChanged);
}


pub fn timelineChanged(_: void, session: windows.GlobalSystemMediaTransportControlsSession) !void {
    const timeline = try session.GetTimelineProperties();
    defer timeline.Release();

    const timestamp = std.time.milliTimestamp();

    // perhaps when working with COM stuff we can use RW locks
    context.mutex.lock();
    defer context.mutex.unlock();

    context.timeline.last_updated = timestamp;
    context.timeline.end_time = @divTrunc(timeline.EndTime(), 10000);
    context.timeline.position = @divTrunc(timeline.Position(), 10000);
}
