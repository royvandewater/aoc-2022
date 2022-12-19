const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("day1", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const input_tests = b.addTest("src/input.zig");
    input_tests.setTarget(target);
    input_tests.setBuildMode(mode);

    const stage_1_tests = b.addTest("src/stage_1.zig");
    stage_1_tests.setTarget(target);
    stage_1_tests.setBuildMode(mode);

    const stage_2_tests = b.addTest("src/stage_2.zig");
    stage_2_tests.setTarget(target);
    stage_2_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
    test_step.dependOn(&input_tests.step);
    test_step.dependOn(&stage_1_tests.step);
    test_step.dependOn(&stage_2_tests.step);

    const test_stage_2_step = b.step("test:stage_2", "Run stage 2 unit tests");
    test_stage_2_step.dependOn(&stage_2_tests.step);
}
