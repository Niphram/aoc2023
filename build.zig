const std = @import("std");
const Build = std.Build;
const CompileStep = std.Build.Step.Compile;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    // Set up an exe for each day
    for (1..25) |day| {
        const dayString = b.fmt("day{:0>2}", .{day});
        const zigFile = b.fmt("src/{s}.zig", .{dayString});

        std.fs.Dir.access(b.build_root.handle, zigFile, std.fs.File.OpenFlags{}) catch {
            continue;
        };

        const exe = b.addExecutable(.{
            .name = dayString,
            .root_source_file = .{ .path = zigFile },
            .target = target,
            .optimize = mode,
        });

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_desc = b.fmt("Run {s}", .{dayString});
        const run_step = b.step(dayString, run_desc);
        run_step.dependOn(&run_cmd.step);
    }
}
