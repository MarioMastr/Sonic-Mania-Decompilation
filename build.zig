const std = @import("std");
const objects = @import("SonicMania/Objects.zig");

const GAME_STATIC = false;
const GAME_INCREMENTAL_BUILD = false;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "Game",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
        .linkage = if (GAME_STATIC) .static else .dynamic,
    });

    var sourceFiles: []const []const u8 = undefined;

    if (GAME_INCREMENTAL_BUILD) {
        sourceFiles = .{"SonicMania/Game.c", "SonicMania/Objects/All.c"};
    } else {
        sourceFiles = .{"SonicMania/Game.c"} ++ objects.sources;
    }

    lib.addCSourceFiles(.{ .files = sourceFiles, });

    lib.addIncludePath(b.path("SonicMania/"));
    lib.addIncludePath(b.path("SonicMania/Objects/"));

    if (target.result.os.tag == .windows) {
        lib.root_module.addCMacro("_CRT_SECURE_NO_WARNINGS", "1");
    }

    lib.linkLibC();
    b.installArtifact(lib);
}