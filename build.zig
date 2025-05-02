const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const extras = b.createModule(.{
        .root_source_file = b.path("extras.zig"),
        .target = target,
        .optimize = optimize,
    });

    const puzzles = [_][]const u8{ "7", "8" };

    inline for (puzzles) |puzzle| {
        const src = "day" ++ puzzle ++ "/main.zig";
        const exe = b.addExecutable(.{
            .name = "day" ++ puzzle,
            .root_source_file = b.path(src),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("extras", extras);
        b.installArtifact(exe);
        const run_step = b.step("run" ++ puzzle, "run day" ++ puzzle ++ " problem");
        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_exe.addArgs(args);
        }
        run_step.dependOn(&run_exe.step);

        const @"test" = b.addTest(.{
            .root_module = exe.root_module,
        });
        const test_step = b.step("test" ++ puzzle, "test day" ++ puzzle ++ " problem");
        const run_test = b.addRunArtifact(@"test");
        test_step.dependOn(&run_test.step);
    }
}
