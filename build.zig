const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const extras = b.createModule(.{
        .root_source_file = b.path("extras.zig"),
        .target = target,
        .optimize = optimize,
    });

    const day7_exe = b.addExecutable(.{
        .name = "day7",
        .root_source_file = b.path("day7/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    day7_exe.root_module.addImport("extras", extras);
    b.installArtifact(day7_exe);
    const day7_run_step = b.step("run7", "run day7 problem");
    const day7_run_exe = b.addRunArtifact(day7_exe);
    if (b.args) |args| {
        day7_run_exe.addArgs(args);
    }
    day7_run_step.dependOn(&day7_run_exe.step);

    const day7_test = b.addTest(.{
        .root_module = day7_exe.root_module,
    });
    const day7_test_step = b.step("test7", "test day7 problem");
    const day7_run_test = b.addRunArtifact(day7_test);
    day7_test_step.dependOn(&day7_run_test.step);
}
