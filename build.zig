const std = @import("std");
const Build = std.Build;
const CompileStep = std.Build.Step.Compile;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const run_all = b.step("run_all", "Run all days");

    const generate = b.step("generate", "Generate stub files from template/template.zig");
    const build_generate = b.addExecutable(.{
        .name = "generate",
        .root_source_file = .{ .path = "template/generate.zig" },
        .optimize = .ReleaseSafe,
    });

    const run_generate = b.addRunArtifact(build_generate);
    run_generate.setCwd(.{ .path = std.fs.path.dirname(@src().file).? });
    generate.dependOn(&run_generate.step);

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
        run_all.dependOn(&run_cmd.step);
    }
}
