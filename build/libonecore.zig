const std = @import("std");

pub fn buildLibrary(b: *std.Build, options: anytype) *std.Build.Step.Compile {
    const target = options.target;
    const optimize = options.optimize;

    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const onecore = b.dependency("onecore", .{});

    mod.linkSystemLibrary("dwrite", .{});

    mod.addCMacro("ONECORE_DIRECTWRITE_LOADER_IMPLEMENTATION", "");
    mod.addCMacro("ONECORE_DIRECTWRITE_FINDER_IMPLEMENTATION", "");
    mod.addCSourceFile(.{ .file = onecore.path("onecore.h") });

    return b.addLibrary(.{
        .name = "onecore",
        .root_module = mod,
    });
}
