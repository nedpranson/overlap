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

    lock: Thread.RwLock,

    manager: windows.GlobalSystemMediaTransportControlsSessionManager,
    session_changed: i64,

    player: ?Player,

    const Player = struct {
        session: windows.GlobalSystemMediaTransportControlsSession,
        timeline_changed: i64,

        timeline: struct {
            last_updated: i64,
            end_time: i64,
            position: i64,
        }
    };

    fn init(c: *Context, gpa: Allocator) !void {
        const manager = try (try windows.GlobalSystemMediaTransportControlsSessionManager.RequestAsync()).getAndForget(gpa);
        errdefer manager.Release();

        c.* = .{
            .gpa = gpa,
            .lock = .{},
            .manager = manager,
            .player = null,
            .session_changed = undefined,
        };

        try handleSession(c, c.manager);

        c.session_changed = try manager.CurrentSessionChanged(gpa, c, handleSession);
        errdefer manager.RemoveCurrentSessionChanged(c.session_changed) catch unreachable;
    }

    fn handleSession(c: *Context, _: windows.GlobalSystemMediaTransportControlsSessionManager) !void {
        c.lock.lock();
        defer c.lock.unlock();

        if (c.player) |player| {
            player.session.RemoveTimelinePropertiesChanged(player.timeline_changed) catch unreachable;
            player.session.Release();
            c.player = null;
        }

        const session = (try c.manager.GetCurrentSession()) orelse return;
        var player: Player = .{ 
            .session = session,
            .timeline_changed = undefined,
            .timeline = undefined,
        };
        
        const timeline = try session.GetTimelineProperties();
        defer timeline.Release();

        const timestamp = std.time.milliTimestamp();

        player.timeline.last_updated = timestamp;
        player.timeline.end_time = @divTrunc(timeline.EndTime(), 10000);
        player.timeline.position = @divTrunc(timeline.Position(), 10000);

        player.timeline_changed = try session.TimelinePropertiesChanged(c.gpa, c, handleTimeline);
        errdefer player.session.RemoveTimelinePropertiesChanged(player.timeline_changed) catch unreachable;

        c.player = player;
    }

    fn handleTimeline(c: *Context, _: windows.GlobalSystemMediaTransportControlsSession) !void {
        c.lock.lock();
        defer c.lock.unlock();

        // this is probs wrong as this func can unlock when session was set to null?
        var player = &c.player.?;

        const timeline = try player.session.GetTimelineProperties();
        defer timeline.Release();

        const timestamp = std.time.milliTimestamp();

        player.timeline.last_updated = timestamp;
        player.timeline.end_time = @divTrunc(timeline.EndTime(), 10000);
        player.timeline.position = @divTrunc(timeline.Position(), 10000);
    }

    fn deinit(c: *Context) void {
        c.manager.RemoveCurrentSessionChanged(c.session_changed) catch unreachable;

        if (c.player) |player| {
            player.session.RemoveTimelinePropertiesChanged(player.timeline_changed) catch unreachable;
            player.session.Release();
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
        c.lock.lockShared();
        defer c.lock.unlockShared();

        const player = c.player orelse return null;

        const playback_info = player.session.GetPlaybackInfo() catch return null;
        defer playback_info.Release();

        const position = blk: {
            if (playback_info.PlaybackStatus() != .Playing) {
                break :blk player.timeline.position;
            }

            const timestamp = std.time.milliTimestamp();
            const elapsed = timestamp - player.timeline.last_updated;

            break :blk player.timeline.position + elapsed;
        };

        return .{
            .position = position,
            .end_time = player.timeline.end_time,
        };
    }
};

var ctx: Context = undefined;

pub fn setup(gpa: Allocator) !void {
    try windows.RoInitialize(windows.RO_INIT_MULTITHREADED);
    errdefer windows.RoUninitialize();

    try ctx.init(gpa);
    errdefer ctx.deinit();
}

pub fn cleanup() void {
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
