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

var token: i64 = undefined;

pub fn setup() !void {
    const allocator = gpa.allocator();

    try windows.RoInitialize(windows.RO_INIT_MULTITHREADED);
    errdefer windows.RoUninitialize();

    manager = try (try windows.GlobalSystemMediaTransportControlsSessionManager.RequestAsync()).getAndForget(allocator);
    errdefer manager.Release();

    try sessionChanged({}, manager);

    token = try manager.CurrentSessionChanged(allocator, {}, sessionChanged);
    errdefer manager.RemoveCurrentSessionChanged(token) catch unreachable;
}

pub fn cleanup() void {
    // free that id only then release

    if (context.session) |session| {
        session.Release();
    }

    manager.RemoveCurrentSessionChanged(token) catch unreachable;
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

        context.session = (try manager.GetCurrentSession()) orelse return;
        break :blk context.session.?;
    };

    try timelineChanged({}, session);
    try propartiesChanged({}, session);

    _ = try session.TimelinePropertiesChanged(gpa.allocator(), {}, timelineChanged);
    _ = try session.MediaPropertiesChanged(gpa.allocator(), {}, propartiesChanged);
}

pub fn propartiesChanged(_: void, session: windows.GlobalSystemMediaTransportControlsSession) !void {
    const properties = try (try session.TryGetMediaPropertiesAsync()).getAndForget(gpa.allocator());
    defer properties.Release();

    const thumbnail = (try properties.Thumbnail()) orelse return;
    defer thumbnail.Release();

    const stream = try (try thumbnail.OpenReadAsync()).getAndForget(gpa.allocator());
    defer stream.Release();

    const decoder = try (try windows.BitmapDecoder.CreateAsync(@ptrCast(stream))).getAndForget(gpa.allocator());
    defer decoder.Release();

    const frame = try (try decoder.GetFrameAsync(0)).getAndForget(gpa.allocator());
    defer frame.Release();

    const transform = try windows.IBitmapTransform.new();
    defer transform.Release();

    transform.put_InterpolationMode(.Fant);

    transform.put_ScaledHeight(64);
    transform.put_ScaledWidth(64);

    const pixels = try (try frame.GetPixelDataTransformedAsync(
        windows.BitmapPixelFormat_Rgba8,
        windows.BitmapAlphaMode_Premultiplied,
        transform,
        windows.ExifOrientationMode_IgnoreExifOrientation,
        windows.ColorManagementMode_DoNotColorManage,
    )).getAndForget(gpa.allocator());
    errdefer pixels.Release();
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
