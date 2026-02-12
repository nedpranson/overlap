const std = @import("std");
const Gui = @import("Gui.zig");
const main = @import("main.zig");
const FontRenderer = @import("graphics/FontRenderer.zig");

const atomic = std.atomic;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;
const assert = std.debug.assert;

const State = enum(u32) {
    uninitialized,
    initializing,
    initialized,
    failure,
};

var state: atomic.Value(State) = .init(.uninitialized);

// todo: find a better place for this!!!
pub var font_renderer: FontRenderer = undefined;

pub fn init(gpa: Allocator) !void {
    const err = main.setup(gpa);
    font_renderer = FontRenderer.init(gpa) catch unreachable;
    state.store(if (std.meta.isError(err)) .failure else .initialized, .release);
    return err;
}

pub fn deinit() void {
    // todo: enable deinit on, mb not
    assert(state.load(.unordered) == .initialized);
    main.cleanup();
    font_renderer.deinit();
}

// todo: return bool as now we will do some backend render code of 0 objects
pub fn render(gui: *Gui) void {
    while (true) {
        switch (state.load(.acquire)) {
            .uninitialized => if (state.cmpxchgWeak(.uninitialized, .initializing, .release, .monotonic) == null) {
                @import("libmain.zig").wake_ev.set();
            },
            .initializing => atomic.spinLoopHint(),
            .initialized => return main.render(gui),
            .failure => return,
        }
    }
}
