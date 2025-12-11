const std = @import("std");
const libdetours = @import("build/libdetours.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const fat = b.dependency("fat", .{
        .target = target,
        .optimize = optimize,
    });

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/libmain2.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "overlap",
        .root_module = lib_mod,
    });

    lib.root_module.addImport("fat", fat.module("fat"));

    const detours = libdetours.buildLibrary(b, .{
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibrary(detours);

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
