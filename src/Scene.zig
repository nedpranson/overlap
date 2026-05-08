const Scene = @This();

const std = @import("std");
const gfx = @import("graphics.zig");
const windows = @import("windows.zig");

image: ?gfx.Image,

var cover: ?windows.PixelDataProvider = null;

pub fn init(b: *gfx.Backend) !Scene {
    if (cover) |c| {
        return .{
            .image = try b.vtable.image(b, .{
                .data = c.DetachPixelData(),
                .width = 64,
                .height = 64,
            }),
        };
    }

    return .{
        .image = null,
    };
}

pub fn deinit(s: *Scene) void {
    if (s.image) |img| {
        img.deinit(img);
    }
}

pub fn frame(s: *Scene, gs: *gfx.Surface) void {
    gs.rect(.{ 0.0, 0.0 }, .{ 130.0, 130.0 }, 0x808080FF);
    if (s.image) |img| {
        gs.image(.{ 30.0, 30.0 }, .{ 100.0, 100.0 }, img);
    }
}

pub fn main(io: std.Io, gpa: std.mem.Allocator) !void {
    _ = gpa;

    try windows.RoInitialize(.MULTITHREADED);
    defer windows.RoUninitialize();

    const manager = try windows.GlobalSystemMediaTransportControlsSessionManager.Request(io);
    defer manager.Release();

    if (try manager.GetCurrentSession()) |session| {
        defer session.Release();

        const props = try session.TryGetMediaProperties(io);
        defer props.Release();

        if (try props.Thumbnail()) |thumbnail| {
            cover = try getPixels(io, thumbnail, try session.SourceAppUserModelId());
        }
    }
    defer if (cover) |c|
        c.Release();

    // const token = try manager.CurrentSessionChanged(gpa, {}, struct {
    //     fn invokeFn(_: void, _: windows.GlobalSystemMediaTransportControlsSessionManager) !void {
    //         windows.OutputDebugString("session changed!");
    //     }
    // }.invokeFn);
    // defer manager.RemoveCurrentSessionChanged(token) catch unreachable;


    // need some lib thingy lib.wait() or smth
    std.debug.assert(windows.kernel32.WaitForSingleObjectEx(@import("libmain.zig").wake_ev, windows.INFINITE, .FALSE) == windows.WAIT_OBJECT_0);
}

fn getPixels(io: std.Io, thumbnail: windows.RandomAccessStreamReference, model_id: []const u16) !windows.PixelDataProvider {
    const stream = try thumbnail.OpenRead(io);
    defer stream.Release();

    const decoder = try windows.BitmapDecoder.Create(@ptrCast(stream), io);
    defer decoder.Release();

    const frameeee = try decoder.GetFrame(io, 0);
    defer frameeee.Release();

    const transform = try windows.IBitmapTransform.new();
    defer transform.Release();

    transform.put_InterpolationMode(.Fant);

    const spotify_packaged_id = std.unicode.utf8ToUtf16LeStringLiteral("SpotifyAB.SpotifyMusic_zpdnekdrzrea0!Spotify");
    const spotify_unpackaged_id = std.unicode.utf8ToUtf16LeStringLiteral("Spotify.exe");

    // crops out Spotifies branding from original thumbnail's image.
    if (std.mem.eql(u16, model_id, spotify_packaged_id) or std.mem.eql(u16, model_id, spotify_unpackaged_id)) {
        // Perhaps this solution does not look so great, but I think it is the best option.

        transform.put_ScaledHeight(@intFromFloat(64.0 * 1.2821));
        transform.put_ScaledWidth(@intFromFloat(64.0 * 1.2821));

        transform.put_Bounds(.{
            .X = @intFromFloat(0.11 * 1.2821 * 64.0),
            .Y = 0,
            .Width = 64,
            .Height = 64,
        });
    } else if (frameeee.PixelWidth() != frameeee.PixelHeight()) {
        const fwidth: f32 = @floatFromInt(frameeee.PixelWidth());
        const fheight: f32 = @floatFromInt(frameeee.PixelHeight());

        const aspect = fwidth / fheight;

        const scaled_width: u32 = @intFromFloat(64.0 * @max(1.0, aspect));
        const scaled_height: u32 = @intFromFloat(64.0 / @min(1.0, aspect));

        transform.put_ScaledWidth(scaled_width);
        transform.put_ScaledHeight(scaled_height);

        const off_x = (scaled_width - 64) >> 1;
        const off_y = (scaled_height - 64) >> 1;

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

    return frameeee.GetPixelDataTransformed(
        io,
        windows.BitmapPixelFormat_Rgba8,
        windows.BitmapAlphaMode_Premultiplied,
        transform,
        windows.ExifOrientationMode_IgnoreExifOrientation,
        windows.ColorManagementMode_DoNotColorManage,
    );
}
