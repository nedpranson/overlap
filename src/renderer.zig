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
    exiting,
    exited
};

var state: atomic.Value(State) = .init(.uninitialized);

// todo: on failure we need to detach our selfs
// shit

fn setup(gpa: Allocator) bool {
    main.setup(gpa) catch |err| {
        std.log.err("could not setup: {}", .{err});
        return false;
    };
    return true;
}

pub fn cleanup() void {
    while (true) {
        switch (state.load(.acquire)) {
            .initialized => if (state.cmpxchgWeak(.initialized, .exiting, .release, .monotonic) == null) {
                main.cleanup();
                state.store(.exited, .release);
            },
            .initializing => atomic.spinLoopHint(),
            .failure, .uninitialized, .exiting, .exited => return,
        }
    }
}

pub fn render(gpa: Allocator, gui: *Gui) void {
    while (true) {
        switch (state.load(.acquire)) {
            .initialized => return main.render(gui),
            .initializing => atomic.spinLoopHint(),
            .failure, .exiting, .exited => return,
            .uninitialized => if (state.cmpxchgWeak(.uninitialized, .initializing, .release, .monotonic) == null) {
                const s: State = if (@call(.always_inline, setup, .{gpa})) .initialized else .failure;
                state.store(s, .release);
            },
        }
    }
}
