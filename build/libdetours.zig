const std = @import("std");

pub fn buildLibrary(b: *std.Build, options: anytype) *std.Build.Step.Compile {
    const target = options.target;
    const optimize = options.optimize;

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "detours",
        .root_module = lib_mod,
    });

    const detours = b.dependency("detours", .{
        .target = target,
        .optimize = optimize,
    });

    // when compiling with msvc is is needed to link with libc not libcpp
    // https://github.com/ziglang/zig/issues/5312
    if (target.result.abi == .msvc) {
        lib.linkLibC();
    } else {
        lib.linkLibCpp();
    }

    var flags_buf: [5][]const u8 = undefined;
    var flags = std.ArrayList([]const u8).initBuffer(&flags_buf);

    flags.appendAssumeCapacity("-fno-sanitize=undefined");
    flags.appendAssumeCapacity("-DWIN32_LEAN_AND_MEAN");

    switch (target.result.cpu.arch) {
        .x86 => {
            flags.appendAssumeCapacity("-DDETOURS_X86");
            flags.appendAssumeCapacity("-DDETOURS_32BIT");
        },
        .x86_64 => {
            flags.appendAssumeCapacity("-DDETOURS_X64");
            flags.appendAssumeCapacity("-DDETOURS_64BIT");
        },
        .arm => {
            flags.appendAssumeCapacity("-DDETOURS_ARM");
            flags.appendAssumeCapacity("-DDETOURS_32BIT");
        },
        .aarch64 => {
            flags.appendAssumeCapacity("-DDETOURS_ARM64");
            flags.appendAssumeCapacity("-DDETOURS_64BIT");
        },
        else => {
            std.debug.panic("Unsupported CPU architecture: {}", .{target.result.cpu.arch});
        },
    }

    lib.addIncludePath(detours.path("src"));

    lib.addCSourceFiles(.{
        .root = detours.path("src"),
        .files = &.{
            "creatwth.cpp",
            "detours.cpp",
            "disasm.cpp",
            "disolarm.cpp",
            "disolarm64.cpp",
            "disolia64.cpp",
            "disolx64.cpp",
            "disolx86.cpp",
            "image.cpp",
            "modules.cpp",
        },
        .flags = flags.items,
    });

    b.installArtifact(lib);

    return lib;
}
