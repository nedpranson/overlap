const std = @import("std");
const windows = @import("windows.zig");
const Gui = @import("Gui.zig");
//const Image = @import("graphics/Image.zig");

const unicode = std.unicode;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;

const Context = struct {
    gpa: Allocator,

    // todo: make it not recurse make it clean man
    // todo: make it robust
    mutex: Thread.Mutex.Recursive,

    manager: windows.GlobalSystemMediaTransportControlsSessionManager,
    session: ?windows.GlobalSystemMediaTransportControlsSession,
    
    tokens: struct {
        session_changed: i64,
        timeline_changed: ?i64,
    },

    timeline: struct {
        last_updated: i64,
        end_time: i64,
        position: i64,
    },

    // todo: group this timeline and nullable tokens into some Session struct idk

    fn init(c: *Context, gpa: Allocator) !void {
        const manager = try (try windows.GlobalSystemMediaTransportControlsSessionManager.RequestAsync()).getAndForget(gpa);
        errdefer manager.Release();

        c.* = .{
            .gpa = gpa,
            .mutex = .init,
            .manager = manager,
            .session = null,
            .tokens = .{
                .session_changed = undefined,
                .timeline_changed = null,
            },
            .timeline = undefined,
        };

        c.tokens.session_changed = try manager.CurrentSessionChanged(gpa, c, handleSession);
        errdefer manager.RemoveCurrentSessionChanged(c.tokens.session_changed) catch unreachable;

        try handleSession(c, c.manager);
    }

    fn handleSession(c: *Context, _: windows.GlobalSystemMediaTransportControlsSessionManager) !void {
        c.mutex.lock();
        defer c.mutex.unlock();

        if (c.session) |ses| {
            ses.RemoveTimelinePropertiesChanged(c.tokens.timeline_changed.?) catch unreachable;
            ses.Release();
        }

        c.session = try ctx.manager.GetCurrentSession();
        if (c.session) |session| {
            c.tokens.timeline_changed = try session.TimelinePropertiesChanged(c.gpa, c, handleTimeline);

            try handleTimeline(c, session);
        }
    }

    fn handleTimeline(c: *Context, session: windows.GlobalSystemMediaTransportControlsSession) !void {
        c.mutex.lock();
        defer c.mutex.unlock();

        const timeline = try session.GetTimelineProperties();
        defer timeline.Release();

        const timestamp = std.time.milliTimestamp();

        c.timeline.last_updated = timestamp;
        c.timeline.end_time = @divTrunc(timeline.EndTime(), 10000);
        c.timeline.position = @divTrunc(timeline.Position(), 10000);
    }

    fn deinit(c: *Context) void {
        c.manager.RemoveCurrentSessionChanged(c.tokens.session_changed) catch unreachable;

        if (c.session) |session| {
            session.RemoveTimelinePropertiesChanged(c.tokens.timeline_changed.?) catch unreachable;
            session.Release();
        }

        // wait till all work is done! like in handleSessions and other handles
        // as now as we deinit object handleSession can be running

        c.manager.Release();
        c.* = undefined;
    }

    const PlaybackInfo = struct {
        position: i64,
        end_time: i64,
    };

    fn getPlaybackInfo(c: *Context) ?PlaybackInfo {
        c.mutex.lock();
        defer c.mutex.unlock();

        // perhaps just get timeline props here?

        const session = c.session orelse return null;

        const playback_info = session.GetPlaybackInfo() catch return null;
        defer playback_info.Release();

        const position = blk: {
            if (playback_info.PlaybackStatus() != .Playing) {
                break :blk c.timeline.position;
            }

            const timestamp = std.time.milliTimestamp();
            const elapsed = timestamp - c.timeline.last_updated;

            break :blk c.timeline.position + elapsed;
        };

        return .{
            .position = position,
            .end_time = c.timeline.end_time,
        };
    }
};

var ctx: Context = undefined;

pub fn setup(gpa: Allocator) !void {
    std.log.debug("hello from: {}\n", .{std.Thread.getCurrentId()});

    try windows.RoInitialize(windows.RO_INIT_MULTITHREADED);
    errdefer windows.RoUninitialize();

    try ctx.init(gpa);
    errdefer ctx.deinit();
}

pub fn cleanup() void {
    std.log.debug("bye from: {}\n", .{std.Thread.getCurrentId()});

    ctx.deinit();
    windows.RoUninitialize();
}

pub fn render(gui: *Gui) void {
    const playback_info = ctx.getPlaybackInfo() orelse return;

    const x = 0;
    const y = 1;

    const pos = &[2]f32{ 24.0, 24.0 };

    const image_size = 64.0;
    const padding = 16.0;

    const width = 198.0;

    gui.rect(.{ -1.0 + pos[x], -1.0 + pos[y] }, .{ pos[x] + image_size + padding + width + padding + 1.0, pos[y] + image_size + 1.0 }, 0x202E36FF);
    gui.rect(.{ pos[x], pos[y] }, .{ pos[x] + image_size + padding + width + padding, pos[y] + image_size }, 0x10191EFF);

    const bar_max_width = image_size + padding + width + padding + 2.0;
    const bar_width = @min(@as(f32, @floatFromInt(playback_info.position)) / @as(f32, @floatFromInt(playback_info.end_time)), 1.0) * bar_max_width;
    const fraction = bar_width - @floor(bar_width);

    gui.rect(.{ -1.0 + pos[x], pos[y] + image_size }, .{ -1.0 + pos[x] + @floor(bar_width), pos[y] + image_size + 1.0 }, 0x00DFA2FF);
    if (fraction > 0.0) {
        // making it smoother
        const col = 0x00DFA200 + @as(u32, @intFromFloat(fraction * 255.0));
        gui.rect(.{ -1.0 + pos[x] + @floor(bar_width), pos[y] + image_size }, .{ -1.0 + pos[x] + @floor(bar_width) + 1.0, pos[y] + image_size + 1.0 }, col);
    }
}
