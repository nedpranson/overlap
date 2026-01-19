const std = @import("std");
const Gui = @import("Gui.zig");
const main = @import("main.zig");

const atomic = std.atomic;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;

const State = enum(u8) {
    initialized,
    initializing,
    failure,
    uninitialized,
    exiting,
    exited
};

var state: atomic.Value(State) = .init(.uninitialized);
var thread: Thread = undefined;

var reset_event: Thread.ResetEvent = .{};

// todo: need to detach on on .failure state!

fn setup(gpa: Allocator) void {
    main.setup(gpa) catch |err| {
        std.debug.print("error: {s}\n", .{@errorName(err)});
        if (@errorReturnTrace()) |trace| {
            std.debug.dumpStackTrace(trace.*);
        }
        state.store(.failure, .release);
        return;
    };

    state.store(.initialized, .release);
    reset_event.wait();

    main.cleanup();
}

pub fn cleanup() void {
    while (true) {
        switch (state.load(.acquire)) {
            .initialized => if (state.cmpxchgWeak(.initialized, .exiting, .release, .monotonic) == null) {
                reset_event.set();

                thread.join();
                thread = undefined;

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
                thread = Thread.spawn(.{}, setup, .{gpa}) catch blk: {
                    state.store(.failure, .release);
                    break :blk undefined;
                };
            },
        }
    }
}
