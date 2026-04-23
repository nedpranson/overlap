const std = @import("std");
const libdetours = @import("build/libdetours.zig");
const libonecore = @import("build/libonecore.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .os_tag = .windows } });
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/libmain.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "overlap",
        .root_module = lib_mod,
    });

    const detours = libdetours.buildLibrary(b, .{
        .target = target,
        .optimize = optimize,
    });

    const onecore = libonecore.buildLibrary(b, .{
        .target = target,
        .optimize = optimize,
    });

    lib.root_module.linkLibrary(detours);
    lib.root_module.linkLibrary(onecore);

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
