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

    lib.addIncludePath(detours.path("src"));
    lib.root_module.addCMacro("WIN32_LEAN_AND_MEAN", "");

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
        .flags = &.{
            "-fno-sanitize=undefined",
        },
    });

    // todo: just add flags

    switch (target.result.cpu.arch) {
        .x86 => {
            lib.root_module.addCMacro("DETOURS_X86", "1");
        },
        .x86_64 => {
            lib.root_module.addCMacro("DETOURS_X64", "1");
            lib.root_module.addCMacro("DETOURS_64BIT", "1");
        },
        .arm => {
            lib.root_module.addCMacro("DETOURS_ARM", "1");
        },
        .aarch64 => {
            lib.root_module.addCMacro("DETOURS_ARM64", "1");
            lib.root_module.addCMacro("DETOURS_64BIT", "1");
        },
        else => {
            std.debug.panic(
                "Unsupported CPU architecture: {}",
                .{target.result.cpu.arch},
            );
        },
    }

    b.installArtifact(lib);

    return lib;
}
