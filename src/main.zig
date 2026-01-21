const std = @import("std");
const windows = @import("windows.zig");
const Gui = @import("Gui.zig");
const Image = @import("graphics/Image.zig");

const unicode = std.unicode;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;

const Context = struct {
    gpa: Allocator,

    lock: Thread.RwLock,

    manager: windows.GlobalSystemMediaTransportControlsSessionManager,
    session_changed: i64,

    cover: *Image,
    player: ?Player,

    const Player = struct {
        session: windows.GlobalSystemMediaTransportControlsSession,

        timeline_changed: i64,
        properties_changed: i64,

        timeline: struct {
            last_updated: i64,
            end_time: i64,
            position: i64,
        }
    };

    fn init(c: *Context, gpa: Allocator) !void {
        const manager = try (try windows.GlobalSystemMediaTransportControlsSessionManager.RequestAsync()).getAndForget(gpa);
        errdefer manager.Release();

        const pixels = &[_]u8{0xFF} ** 64 ** 64;
        const cover = try Image.init(c.gpa, .{
            .width = 64,
            .height = 64,
            .data = pixels,
            .format = .rgba,
            .usage = .dynamic,
        });
        errdefer cover.deinit();

        c.* = .{
            .gpa = gpa,
            .lock = .{},
            .manager = manager,
            .player = null,
            .cover = cover,
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
            .properties_changed = undefined,
            .timeline = undefined,
        };

        // todo: tidy everything here
        
        const timeline = try session.GetTimelineProperties();
        defer timeline.Release();

        const timestamp = std.time.milliTimestamp();

        player.timeline.last_updated = timestamp;
        player.timeline.end_time = @divTrunc(timeline.EndTime(), 10000);
        player.timeline.position = @divTrunc(timeline.Position(), 10000);

        player.timeline_changed = try session.TimelinePropertiesChanged(c.gpa, c, handleTimeline);
        errdefer player.session.RemoveTimelinePropertiesChanged(player.timeline_changed) catch unreachable;

        player.properties_changed = try session.MediaPropertiesChanged(c.gpa, c, handleProperties);
        // todo: remove!!! props changed 

        c.player = player;
    }

    fn handleTimeline(c: *Context, _: windows.GlobalSystemMediaTransportControlsSession) !void {
        c.lock.lock();
        defer c.lock.unlock();

        var player = &(c.player orelse return);

        const timeline = try player.session.GetTimelineProperties();
        defer timeline.Release();

        const timestamp = std.time.milliTimestamp();

        player.timeline.last_updated = timestamp;
        player.timeline.end_time = @divTrunc(timeline.EndTime(), 10000);
        player.timeline.position = @divTrunc(timeline.Position(), 10000);
    }

    fn handleProperties(c: *Context, _: windows.GlobalSystemMediaTransportControlsSession) !void {
        // todo: we should reduce our locks as there
        //       random longer locks can cauze some frame drops
        //       as render thread will wait till this func rasterizes cover image and stuff
        c.lock.lock();
        defer c.lock.unlock();

        var player = &(c.player orelse return);

        // todo: update like artist and stuff

        //if (player.cover) |cover| {
            // todo: think is deinit call is even clear as it just decRef this call is like hidden behaviour
            //cover.deinit();
            //player.cover = null;
        //}

        const properties = try (try player.session.TryGetMediaPropertiesAsync()).getAndForget(c.gpa);
        defer properties.Release();

        const thumbnail = (try properties.Thumbnail()) orelse return;
        defer thumbnail.Release();

        const stream = try (try thumbnail.OpenReadAsync()).getAndForget(c.gpa);
        defer stream.Release();

        const decoder = try (try windows.BitmapDecoder.CreateAsync(@ptrCast(stream))).getAndForget(c.gpa);
        defer decoder.Release();

        const frame = try (try decoder.GetFrameAsync(0)).getAndForget(c.gpa);
        defer frame.Release();

        const transform = try windows.IBitmapTransform.new();
        defer transform.Release();

        transform.put_InterpolationMode(.Fant);

        const spotify_packaged_id = unicode.utf8ToUtf16LeStringLiteral("SpotifyAB.SpotifyMusic_zpdnekdrzrea0!Spotify");
        const spotify_unpackaged_id = unicode.utf8ToUtf16LeStringLiteral("Spotify.exe");

        const model_id = try player.session.SourceAppUserModelId();

        // crops out Spotifies branding from original thumbnail's image.
        if (mem.eql(u16, model_id, spotify_packaged_id) or mem.eql(u16, model_id, spotify_unpackaged_id)) {
            // Perhaps this solution does not look so great, but I think it is the best option.

            transform.put_ScaledHeight(@intFromFloat(64.0 * 1.2821));
            transform.put_ScaledWidth(@intFromFloat(64.0 * 1.2821));

            transform.put_Bounds(.{
                .X = @intFromFloat(0.11 * 1.2821 * 64.0),
                .Y = 0,
                .Width = 64,
                .Height = 64,
            });
        } else {
            transform.put_ScaledHeight(64);
            transform.put_ScaledWidth(64);
        }

        // todo: handle like non square ones

        const pixels = try (try frame.GetPixelDataTransformedAsync(
                windows.BitmapPixelFormat_Rgba8,
                windows.BitmapAlphaMode_Premultiplied,
                transform,
                windows.ExifOrientationMode_IgnoreExifOrientation,
                windows.ColorManagementMode_DoNotColorManage,
        )).getAndForget(c.gpa);
        defer pixels.Release();

        var ptr: [*]const u8 = undefined;
        var len: u32 = undefined;
        pixels.DetachPixelData(&len, &ptr); // todo: add PixelDataProvider

        c.cover.update(ptr[0..len]);
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
        c.cover.deinit();

        c.* = undefined;
    }

    // tood: add like default cover
    const PlaybackInfo = struct {
        cover: *Image,
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
            .cover = c.cover,
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

    gui.image(.{ pos[x], pos[y] }, .{ pos[x] + 64.0, pos[y] + 64.0 }, playback_info.cover);
}
