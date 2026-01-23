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

    // if compiling with msvc we need to link with libc not libcpp
    // https://github.com/ziglang/zig/issues/5312
    if (target.result.abi == .msvc) {
        lib.linkLibC();
    } else {
        lib.linkLibCpp();
    }

    var cflags_buf: [5][]const u8 = undefined;
    var cflags = std.ArrayList([]const u8).initBuffer(&cflags_buf);

    cflags.appendBounded("-fno-sanitize=undefined") catch unreachable;
    cflags.appendBounded("-DWIN32_LEAN_AND_MEAN") catch unreachable;

    switch (target.result.cpu.arch) {
        .x86 => {
            cflags.appendBounded("-DDETOURS_X86") catch unreachable;
            cflags.appendBounded("-DDETOURS_32BIT") catch unreachable;
        },
        .x86_64 => {
            cflags.appendBounded("-DDETOURS_X64") catch unreachable;
            cflags.appendBounded("-DDETOURS_64BIT") catch unreachable;
        },
        .arm => {
            cflags.appendBounded("-DDETOURS_ARM") catch unreachable;
            cflags.appendBounded("-DDETOURS_32BIT") catch unreachable;
        },
        .aarch64 => {
            cflags.appendBounded("-DDETOURS_ARM64") catch unreachable;
            cflags.appendBounded("-DDETOURS_64BIT") catch unreachable;
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
        .flags = cflags.items,
    });

    b.installArtifact(lib);

    return lib;
}
