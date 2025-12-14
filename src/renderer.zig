const std = @import("std");
const Gui = @import("Gui2.zig");
const main = @import("main2.zig");

const atomic = std.atomic;

const State = enum(u8) {
    initialized,
    initializing,
    failure,
    uninitialized,
};

var state: atomic.Value(State) = .init(.uninitialized);

fn setup() bool {
    main.setup() catch |err| {
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

pub fn render(gui: *Gui) void {
    while (true) {
        switch (state.load(.acquire)) {
            .initialized => return main.render(gui),
            .initializing => atomic.spinLoopHint(),
            .failure => return,
            .uninitialized => if (state.cmpxchgWeak(.uninitialized, .initializing, .release, .monotonic) == null) {
                const s: State = if (@call(.always_inline, setup, .{})) .initialized else .failure;
                state.store(s, .release);
            }
        }
    }
}
