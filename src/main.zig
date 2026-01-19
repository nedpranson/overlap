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

    mutex: Thread.Mutex,

    manager: windows.GlobalSystemMediaTransportControlsSessionManager,
    session: ?windows.GlobalSystemMediaTransportControlsSession,
    
    tokens: struct {
        session_changed: i64,
    },

    fn init(c: *Context, gpa: Allocator) !void {
        const manager = try (try windows.GlobalSystemMediaTransportControlsSessionManager.RequestAsync()).getAndForget(gpa);
        errdefer manager.Release();

        const session = try manager.GetCurrentSession();
        errdefer if (session) |ses| ses.Release();

        c.* = .{
            .gpa = gpa,
            .mutex = .{},
            .manager = manager,
            .session = session,
            .tokens = .{
                .session_changed = undefined,
            },
        };

        c.tokens.session_changed = try manager.CurrentSessionChanged(gpa, c, handleSession);
        errdefer manager.RemoveCurrentSessionChanged(c.tokens.session_changed) catch unreachable;

        // init session itself like add all the tokens
        // and only then init session_changed event
    }

    fn handleSession(c: *Context, _: windows.GlobalSystemMediaTransportControlsSessionManager) !void {
        c.mutex.lock();
        defer c.mutex.unlock();

        if (c.session) |ses| ses.Release();
        ctx.session = try ctx.manager.GetCurrentSession();
    }

    fn deinit(c: *Context) void {
        c.manager.RemoveCurrentSessionChanged(c.tokens.session_changed) catch unreachable;

        // wait till all work is done! like in handleSessions and other handles
        // as now as we deinit object handleSession can be running

        if (c.session) |ses| ses.Release();
        c.manager.Release();

        c.* = undefined;
    }

    const PlaybackInfo = struct {
        status: windows.MediaPlaybackStatus,
    };

    fn getPlaybackInfo(c: *Context) ?PlaybackInfo {
        c.mutex.lock();
        defer c.mutex.unlock();

        const session = c.session orelse return null;

        const playback_info = session.GetPlaybackInfo() catch return null;
        defer playback_info.Release();

        return .{
            .status = playback_info.PlaybackStatus(),
        };
    }
};

var ctx: Context = undefined;

pub fn setup(gpa: Allocator) !void {
    windows.RoInitialize() catch unreachable;

    try ctx.init(gpa);
    errdefer ctx.deinit();
}

pub fn cleanup() void {
    windows.RoInitialize() catch unreachable;

    ctx.deinit();
}

pub fn render(gui: *Gui) void {
    //const playback_info = ctx.getPlaybackInfo() orelse return;
    //_ = playback_info;

    const x = 0;
    const y = 1;

    const pos = &[2]f32{ 24.0, 24.0 };

    const image_size = 64.0;
    const padding = 16.0;

    const width = 198.0;

    gui.rect(.{ -1.0 + pos[x], -1.0 + pos[y] }, .{ pos[x] + image_size + padding + width + padding + 1.0, pos[y] + image_size + 1.0 }, 0x202E36FF);
    gui.rect(.{ pos[x], pos[y] }, .{ pos[x] + image_size + padding + width + padding, pos[y] + image_size }, 0x10191EFF);
}
