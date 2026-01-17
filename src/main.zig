const std = @import("std");
const windows = @import("windows.zig");
const Gui = @import("Gui.zig");
const Image = @import("graphics/Image.zig");

const unicode = std.unicode;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;

const Context = struct {
    mutex: Thread.Mutex = .{},

    session: ?windows.GlobalSystemMediaTransportControlsSession = null,

    title: []const u16 = &.{},
    artist: []const u16 = &.{},

    cover: ?struct {
        img: Image,
        pixels: *windows.IPixelDataProvider,
    } = null,

    timeline: struct {
        last_updated: i64 = 0,
        end_time: i64 = 0,
        position: i64 = 0,
    } = .{},
};

// this undefined stuff sucks
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
    // todo: release context cover img
    if (context.session) |session| {
        session.Release();
    }

    gpa.allocator().free(context.title);
    gpa.allocator().free(context.artist);

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


    context.mutex.lock();
    if (context.cover) |cov| {
        gui.image(.{ pos[x], pos[y] }, .{ pos[x] + 64.0, pos[y] + 64.0 }, cov.img);
    }
    context.mutex.unlock();

    // cover

    const progress = blk: {
        context.mutex.lock();
        defer context.mutex.unlock();

        // TODO: capture them errors !!!
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
    const fraction = bar_width - @floor(bar_width);

    // progress bar
    gui.rect(.{ -1.0 + pos[x], pos[y] + image_size }, .{ -1.0 + pos[x] + @floor(bar_width), pos[y] + image_size + 1.0 }, 0x00DFA2FF);
    if (fraction > 0.0) {
        // making it smoother
        const col = 0x00DFA200 + @as(u32, @intFromFloat(fraction * 255.0));
        gui.rect(.{ -1.0 + pos[x] + @floor(bar_width), pos[y] + image_size }, .{ -1.0 + pos[x] + @floor(bar_width) + 1.0, pos[y] + image_size + 1.0 }, col);
    }


    // properties
    // todo: handle err
    //ellipsisW(gui, .{ pos[x] + image_size + padding, pos[y] + padding }, context.title, width, .{ .size = 12.0 }) catch unreachable;
    //ellipsisW(gui, .{ pos[x] + image_size + padding, pos[y] + padding + 20.0 }, context.artist, width, .{ .size = 10.0, .color = 0x808080FF }) catch unreachable;
}

fn ellipsisW(gui: *Gui, pos: [2]f32, msg: []const u16, width: f32, descriptor: Gui.Descriptor) !void {
    // when we will have real kerning and stuff, shaping
    // we could bin search the most optimal path
    const suffix_width = try gui.advanceWidthf('…', descriptor);

    var text_width: f32 = 0.0;
    var cut_width: f32 = 0.0;
    var cut_units: usize = 0;

    var it = unicode.Wtf16LeIterator.init(msg);
    while (it.nextCodepoint()) |codepoint| {
        text_width += try gui.advanceWidthf(codepoint, descriptor);

        if (text_width > width) {
            break;
        }

        if (codepoint != ' ' and width >= text_width + suffix_width) {
            cut_width = text_width;
            cut_units = it.i >> 1;
        }
    }

    if (width >= text_width) {
        try gui.textW(pos, msg, descriptor);
        return;
    }

    try gui.textW(pos, msg[0..cut_units], descriptor);
    try gui.textW(.{ pos[0] + cut_width, pos[1] }, unicode.wtf8ToWtf16LeStringLiteral("…"), descriptor);
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

    const spotify_packaged_id = unicode.utf8ToUtf16LeStringLiteral("SpotifyAB.SpotifyMusic_zpdnekdrzrea0!Spotify");
    const spotify_unpackaged_id = unicode.utf8ToUtf16LeStringLiteral("Spotify.exe");

    const model_id = try session.SourceAppUserModelId();

    // Crops out Spotifies branding from original thumbnail's image.
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
    )).getAndForget(gpa.allocator());
    errdefer pixels.Release();

    context.mutex.lock();
    defer context.mutex.unlock();

    if (context.cover) |cov| {
        cov.img.deinit();
        cov.pixels.Release();
    }

    var ptr: [*]const u8 = undefined;
    var len: u32 = undefined;
    pixels.DetachPixelData(&len, &ptr); // todo: add PixelDataProvider

    context.cover = .{
        .img = .init(.{
            .width = 64,
            .height = 64,
            .data = ptr[0..len],
            .format = .rgba,
        }),
        .pixels = pixels,
    };

    gpa.allocator().free(context.title);
    gpa.allocator().free(context.artist);

    context.title = try gpa.allocator().dupe(u16, properties.Title());
    context.artist = try gpa.allocator().dupe(u16, properties.Artist());
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
