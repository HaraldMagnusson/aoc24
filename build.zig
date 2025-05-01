const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const day7_exe = b.addExecutable(.{
        .name = "day7",
        .root_source_file = b.path("day7/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(day7_exe);
    const day7_step = b.step("run7", "run day7 problem");
    const day7_run = b.addRunArtifact(day7_exe);
    day7_step.dependOn(&day7_run.step);
}
