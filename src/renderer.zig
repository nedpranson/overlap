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

var reset_event_a: Thread.ResetEvent = .{};
var reset_event_b: Thread.ResetEvent = .{};

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
    reset_event_a.wait();

    main.cleanup();
    reset_event_b.set();
}

pub fn cleanup() void {
    while (true) {
        switch (state.load(.acquire)) {
            .initialized => if (state.cmpxchgWeak(.initialized, .exiting, .release, .monotonic) == null) {
                reset_event_a.set();
                reset_event_b.wait(); // todo: remove wait as that setup thread is still executing some code we need join!!!

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
            .uninitialized => if (state.cmpxchgWeak(.uninitialized, .initializing, .release, .monotonic) == null) blk: {
                const thread = Thread.spawn(.{}, setup, .{gpa}) catch {
                    state.store(.failure, .release);
                    break :blk;
                };
                // idk why but it seems when joining thread from another thread it just freezes
                // todo: investigate this maybe it's smth wrong with zig's smth lib
                thread.detach();
            },
        }
    }
}
