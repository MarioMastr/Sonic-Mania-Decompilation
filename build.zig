const std = @import("std");
const objects = @import("SonicMania/Objects.zig");

const GAME_STATIC = false;
const GAME_INCREMENTAL_BUILD = false;

pub const Options = struct {
    RETRO_REVISION: u8,

    RETRO_MOD_LOADER: bool,
    RETRO_MOD_LOADER_VER: u8,
    
    GAME_INCLUDE_EDITOR: bool,

    MANIA_PREPLUS: bool,
    MANIA_FIRST_RELEASE: bool,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const retroRevision     = b.option(u8,   "retro_revision",       "What revision to compile for. Defaults to v5U = 3")                orelse 3;
    const retroModLoader    = b.option(bool, "retro_mod_loader",     "Enables or disables the mod loader.")                              orelse false;
    const retroModLoaderVer = b.option(u8,   "retro_mod_loader_ver", "Sets the mod loader version. Defaults to latest")                  orelse 2;
    const gameIncludeEditor = b.option(bool, "game_include_editor",  "Whether or not to include editor functions. Defaults to true")     orelse true;
    const maniaFirstRelease = b.option(bool, "mania_first_release",  "Whether or not to build Mania's first release. Defaults to false") orelse false;
    const maniaPrePlus      = if (maniaFirstRelease) true else b.option(bool, "mania_pre_plus", "Whether or not to build Mania pre-plus. Defaults to false") orelse false;
    const GAME_VERSION      = if (!maniaPrePlus) 6 else 3;

    const add = b.addOptions();
    add.addOption(u8,   "retro_revision",       retroRevision);
    add.addOption(bool, "retro_mod_loader",     retroModLoader);
    add.addOption(u8,   "retro_mod_loader_ver", retroModLoaderVer);
    add.addOption(bool, "game_include_editor",  gameIncludeEditor);
    add.addOption(bool, "mania_pre_plus",       maniaPrePlus);
    add.addOption(bool, "mania_first_release",  maniaFirstRelease);

    const selectedOptions = Options {
        .RETRO_REVISION = retroRevision,

        .RETRO_MOD_LOADER = retroModLoader,
        .RETRO_MOD_LOADER_VER = retroModLoaderVer,
        
        .GAME_INCLUDE_EDITOR = gameIncludeEditor,

        .MANIA_PREPLUS = maniaPrePlus,
        .MANIA_FIRST_RELEASE = maniaFirstRelease,
    };

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
        sourceFiles = &.{"SonicMania/Game.c", "SonicMania/Objects/All.c"};
    } else {
        sourceFiles = .{"SonicMania/Game.c"} ++ objects.sources;
    }

    lib.addCSourceFiles(.{ .files = sourceFiles, });

    lib.addIncludePath(b.path("SonicMania/"));
    lib.addIncludePath(b.path("SonicMania/Objects/"));

    if (target.result.os.tag == .windows) {
        lib.root_module.addCMacro("_CRT_SECURE_NO_WARNINGS", "1");
    }

    const retroRevBuf  = try std.fmt.allocPrint(b.allocator, "{}", .{selectedOptions.RETRO_REVISION});
    defer b.allocator.free(retroRevBuf);

    const modLoaderBuf = try std.fmt.allocPrint(b.allocator, "{}", .{@intFromBool(selectedOptions.RETRO_MOD_LOADER)});
    defer b.allocator.free(modLoaderBuf);

    const modVerBuf    = try std.fmt.allocPrint(b.allocator, "{}", .{selectedOptions.RETRO_MOD_LOADER_VER});
    defer b.allocator.free(modVerBuf);

    const editorBuf    = try std.fmt.allocPrint(b.allocator, "{}", .{@intFromBool(selectedOptions.GAME_INCLUDE_EDITOR)});
    defer b.allocator.free(editorBuf);

    const prePlusBuf   = try std.fmt.allocPrint(b.allocator, "{}", .{@intFromBool(selectedOptions.MANIA_PREPLUS)});
    defer b.allocator.free(prePlusBuf);

    const firstRelBuf  = try std.fmt.allocPrint(b.allocator, "{}", .{@intFromBool(selectedOptions.MANIA_FIRST_RELEASE)});
    defer b.allocator.free(firstRelBuf);
  
    const gameVerBuf   = try std.fmt.allocPrint(b.allocator, "{}", .{GAME_VERSION});
    defer b.allocator.free(gameVerBuf);

    lib.root_module.addCMacro("RETRO_REVISION", retroRevBuf);
    lib.root_module.addCMacro("RETRO_USE_MOD_LOADER", modLoaderBuf);
    lib.root_module.addCMacro("RETRO_MOD_LOADER_VER", modVerBuf);
    lib.root_module.addCMacro("GAME_INCLUDE_EDITOR", editorBuf);
    lib.root_module.addCMacro("MANIA_PREPLUS", prePlusBuf);
    lib.root_module.addCMacro("MANIA_FIRST_RELEASE", firstRelBuf);
    lib.root_module.addCMacro("GAME_VERSION", gameVerBuf);

    lib.linkLibC();
    b.installArtifact(lib);
}