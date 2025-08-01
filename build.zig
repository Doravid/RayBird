const std = @import("std");
const rlz = @import("raylib-zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    // Web exports are completely separate
    if (target.result.os.tag == .emscripten) {
        const exe_lib = try rlz.emcc.compileForEmscripten(b, "test", "src/main.zig", target, optimize);
        exe_lib.linkLibrary(raylib_artifact);
        exe_lib.root_module.addImport("raylib", raylib);
        exe_lib.root_module.addImport("raygui", raygui);
        // Note that raylib itself is not actually added to the exe_lib output file, so it also needs to be linked with emscripten.
        const link_step = try rlz.emcc.linkWithEmscripten(b, &[_]*std.Build.Step.Compile{ exe_lib, raylib_artifact });
        // This lets your program access files like "resources/my-image.png":
        link_step.addArg("--emrun");
        link_step.addArg("--embed-file");
        link_step.addArg("resources/");
        link_step.addArg("-z");
        link_step.addArg("stack-size=2097152");
        b.getInstallStep().dependOn(&link_step.step);
        const run_step = try rlz.emcc.emscriptenRunStep(b);
        run_step.step.dependOn(&link_step.step);
        const run_option = b.step("run", "Run test");
        run_option.dependOn(&run_step.step);
        return;
    }

    const exe = b.addExecutable(.{ .name = "test", .root_source_file = b.path("src/main.zig"), .optimize = optimize, .target = target });
    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);
    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run test");
    run_step.dependOn(&run_cmd.step);
    b.installArtifact(exe);
}
