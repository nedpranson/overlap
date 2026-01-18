const std = @import("std");
const Gui = @import("Gui.zig");
const main = @import("main.zig");

const atomic = std.atomic;
const Allocator = std.mem.Allocator;

const State = enum(u8) {
    initialized,
    initializing,
    failure,
    uninitialized,
};

var state: atomic.Value(State) = .init(.uninitialized);

fn setup(gpa: Allocator) bool {
    // todo: format error message!
    main.setup(gpa) catch |err| {
        std.log.err("{}", .{err});
        return false;
    };
    return true;
}

pub fn cleanup() void {
    while (true) {
        switch (state.load(.acquire)) {
            .initialized => return main.cleanup(),
            .initializing => atomic.spinLoopHint(),
            .failure, .uninitialized => return,
        }
    }
}

pub fn render(gpa: Allocator, gui: *Gui) void {
    while (true) {
        switch (state.load(.acquire)) {
            .initialized => return main.render(gui),
            .initializing => atomic.spinLoopHint(),
            .failure => return,
            .uninitialized => if (state.cmpxchgWeak(.uninitialized, .initializing, .release, .monotonic) == null) {
                const s: State = if (@call(.always_inline, setup, .{gpa})) .initialized else .failure;
                state.store(s, .release);
            },
        }
    }
}
