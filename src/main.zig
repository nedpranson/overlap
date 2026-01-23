const std = @import("std");
const windows = @import("windows.zig");
const Gui = @import("Gui.zig");
const Image = @import("graphics/Image.zig");

const unicode = std.unicode;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;

// when dumping a stack trace
// we're reacching stack overflows

const Context = struct {
    gpa: Allocator,

    lock: Thread.RwLock,

    manager: windows.GlobalSystemMediaTransportControlsSessionManager,
    session_changed: i64,

    cover: *Image,
    player: ?Player,

    const white_pixels = &[_]u8{0xFF} ** 64 ** 64 ** 4;

    const Timeline = struct {
        last_updated: i64,
        end_time: i64,
        position: i64,
    };

    const Player = struct {
        session: windows.GlobalSystemMediaTransportControlsSession,
        timeline_changed: i64,
        properties_changed: i64,
        timeline: Timeline,
        title: [64]u16,
        artist: [64]u16,
        title_len: u8,
        artist_len: u8,
    };

    fn init(c: *Context, gpa: Allocator) !void {
        const manager = try (try windows.GlobalSystemMediaTransportControlsSessionManager.RequestAsync()).getAndForget(gpa);
        errdefer manager.Release();

        const cover = try Image.init(gpa, .{
            .width = 64,
            .height = 64,
            .data = white_pixels,
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

        ctx_enabled = true;
        try handleSession(c, c.manager);

        c.session_changed = try manager.CurrentSessionChanged(gpa, c, handleSession);
        errdefer manager.RemoveCurrentSessionChanged(c.session_changed) catch unreachable;
    }

    fn handleSession(c: *Context, _: windows.GlobalSystemMediaTransportControlsSessionManager) !void {
        var player: ?Player = null;
        var pixels: ?windows.PixelDataProvider = null;
        defer if (pixels) |p| p.Release();

        if (try c.manager.GetCurrentSession()) |session| {
            const properties = try (try session.TryGetMediaPropertiesAsync()).getAndForget(c.gpa);
            defer properties.Release();

            if (try properties.Thumbnail()) |thumbnail| {
                defer thumbnail.Release();
                pixels = try getThumbnailPixels(c.gpa, thumbnail, try session.SourceAppUserModelId());
            }

            const timeline_changed = try session.TimelinePropertiesChanged(c.gpa, c, handleTimeline);
            errdefer session.RemoveTimelinePropertiesChanged(timeline_changed) catch unreachable;

            const properties_changed = try session.MediaPropertiesChanged(c.gpa, c, handleProperties);
            errdefer session.RemoveMediaPropertiesChanged(properties_changed) catch unreachable;

            const title = properties.Title();
            const artist = properties.Artist();

            const title_len = @min(title.len, 64);
            const artist_len = @min(artist.len, 64);

            player = .{
                .session = session,
                .timeline_changed = timeline_changed,
                .properties_changed = properties_changed,
                .timeline = try getTimeline(session),
                .title = undefined,
                .artist = undefined,
                .title_len = title_len,
                .artist_len = artist_len,
            };

            @memcpy(player.?.title[0..title_len], title[0..title_len]);
            @memcpy(player.?.artist[0..artist_len], artist[0..artist_len]);
        }

        c.lock.lock();
        defer c.lock.unlock();

        if (!ctx_enabled) {
            @branchHint(.cold);
            return;
        }

        if (c.player) |old_player| {
            old_player.session.RemoveTimelinePropertiesChanged(old_player.timeline_changed) catch unreachable;
            old_player.session.RemoveMediaPropertiesChanged(old_player.properties_changed) catch unreachable;
            old_player.session.Release();
        }

        if (pixels) |p| {
            c.cover.update(p.DetachPixelData());
        } else {
            c.cover.update(white_pixels);
        }

        c.player = player;
    }

    fn getTimeline(session: windows.GlobalSystemMediaTransportControlsSession) !Timeline {
        const timestamp = std.time.milliTimestamp();

        const timeline = try session.GetTimelineProperties();
        defer timeline.Release();

        return .{
            .last_updated = timestamp,
            .end_time = @divTrunc(timeline.EndTime(), 10000),
            .position = @divTrunc(timeline.Position(), 10000),
        };
    }

    fn getThumbnailPixels(
        gpa: Allocator,
        thumbnail: windows.RandomAccessStreamReference,
        model_id: []const u16,
    ) !windows.PixelDataProvider {
        const stream = try (try thumbnail.OpenReadAsync()).getAndForget(gpa);
        defer stream.Release();

        const decoder = try (try windows.BitmapDecoder.CreateAsync(@ptrCast(stream))).getAndForget(gpa);
        defer decoder.Release();

        const frame = try (try decoder.GetFrameAsync(0)).getAndForget(gpa);
        defer frame.Release();

        const transform = try windows.IBitmapTransform.new();
        defer transform.Release();

        transform.put_InterpolationMode(.Fant);

        const spotify_packaged_id = unicode.utf8ToUtf16LeStringLiteral("SpotifyAB.SpotifyMusic_zpdnekdrzrea0!Spotify");
        const spotify_unpackaged_id = unicode.utf8ToUtf16LeStringLiteral("Spotify.exe");

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
        } else if (frame.PixelWidth() != frame.PixelHeight()) {
            const fwidth: f32 = @floatFromInt(frame.PixelWidth());
            const fheight: f32 = @floatFromInt(frame.PixelHeight());

            const aspect = fwidth / fheight;

            const scaled_width: u32 = @intFromFloat(64.0 * @max(1.0, aspect));
            const scaled_height: u32 = @intFromFloat(64.0 / @min(1.0, aspect));

            transform.put_ScaledWidth(scaled_width);
            transform.put_ScaledHeight(scaled_height);

            const side = @min(scaled_width, scaled_height);

            const off_x = (side - scaled_width) >> 1;
            const off_y = (side - scaled_height) >> 1;

            transform.put_Bounds(.{
                .X = off_x,
                .Y = off_y,
                .Width = 64,
                .Height = 64,
            });
        } else {
            transform.put_ScaledHeight(64);
            transform.put_ScaledWidth(64);
        }

        return try (try frame.GetPixelDataTransformedAsync(
            windows.BitmapPixelFormat_Rgba8,
            windows.BitmapAlphaMode_Premultiplied,
            transform,
            windows.ExifOrientationMode_IgnoreExifOrientation,
            windows.ColorManagementMode_DoNotColorManage,
        )).getAndForget(gpa);
    }

    fn handleTimeline(c: *Context, _: windows.GlobalSystemMediaTransportControlsSession) !void {
        c.lock.lock();
        defer c.lock.unlock();

        if (!ctx_enabled) {
            @branchHint(.cold);
            return;
        }

        var player = &(c.player orelse return);
        player.timeline = try getTimeline(player.session);
    }

    fn handleProperties(c: *Context, session: windows.GlobalSystemMediaTransportControlsSession) !void {
        const properties = try (try session.TryGetMediaPropertiesAsync()).getAndForget(c.gpa);
        defer properties.Release();

        const pixels = blk: {
            const thumbnail = try properties.Thumbnail() orelse break :blk null;
            defer thumbnail.Release();

            break :blk try getThumbnailPixels(c.gpa, thumbnail, try session.SourceAppUserModelId());
        };
        defer if (pixels) |p| p.Release();

        const title = properties.Title();
        const artist = properties.Artist();

        const title_len = @min(title.len, 64);
        const artist_len = @min(artist.len, 64);

        c.lock.lock();
        defer c.lock.unlock();

        if (!ctx_enabled) {
            @branchHint(.cold);
            return;
        }

        const player = &(c.player orelse return);
        if (player.session.handle != session.handle) return;

        player.title_len = title_len;
        player.artist_len = artist_len;

        @memcpy(player.title[0..title_len], title[0..title_len]);
        @memcpy(player.artist[0..artist_len], artist[0..artist_len]);

        if (pixels) |p| {
            c.cover.update(p.DetachPixelData());
        } else {
            c.cover.update(white_pixels);
        }
    }

    fn deinit(c: *Context) void {
        c.lock.lock();
        ctx_enabled = false;

        c.manager.RemoveCurrentSessionChanged(c.session_changed) catch unreachable;

        if (c.player) |player| {
            player.session.RemoveTimelinePropertiesChanged(player.timeline_changed) catch unreachable;
            player.session.RemoveMediaPropertiesChanged(player.properties_changed) catch unreachable;
            player.session.Release();
        }

        c.manager.Release();
        c.cover.deinit();
        c.lock.unlock();

        c.* = undefined;
    }

    const PlaybackInfo = struct {
        cover: *Image,
        position: i64,
        end_time: i64,
        title_buf: [64]u16,
        artist_buf: [64]u16,
        title_len: u8,
        artist_len: u8,

        pub inline fn title(pi: PlaybackInfo) []const u16 {
            return pi.title_buf[0..pi.title_len];
        }

        pub inline fn artist(pi: PlaybackInfo) []const u16 {
            return pi.artist_buf[0..pi.artist_len];
        }
    };

    // cover can update any time
    // mb for each player allocate its cover
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
            .title_buf = player.title,
            .artist_buf = player.artist,
            .title_len = player.title_len,
            .artist_len = player.artist_len,
        };
    }
};

var ctx: Context = undefined;
// todo: one day we could add some ref to event handler and when it's count reaches 0
//       we can be asured no more callbacks will ever be called
var ctx_enabled = false;

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

    const pos = [2]f32{ 24.0, 24.0 };

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

    gui.textW(.{ pos[x] + image_size + padding, pos[y] + padding }, playback_info.title(), .{ .size = 10.0 });
    gui.textW(.{ pos[x] + image_size + padding, pos[y] + padding + 20.0 }, playback_info.artist(), .{ .size = 10.0, .color = 0x808080FF });
}
