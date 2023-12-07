const std = @import("std");
const util = @import("./util.zig");

const Boat = struct { speed: usize = 0 };

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator;

    // Split input into seeds and category-maps
    const times_s, const distances_s = util.splitScalarOnce(u8, input, '\n');

    var time_iter = std.mem.tokenizeScalar(u8, times_s[9..], ' ');
    var distance_iter = std.mem.tokenizeScalar(u8, distances_s[9..], ' ');

    var total: usize = 1;

    while (time_iter.next()) |time_s| {
        const dis_s = distance_iter.next().?;

        std.debug.print("{s}|{s}\n", .{ time_s, dis_s });

        const time = try std.fmt.parseInt(usize, time_s, 10);
        const dis = try std.fmt.parseInt(usize, dis_s, 10);

        var possible_times: usize = 0;

        for (0..time + 1) |hold_time| {
            const rem_time = time - hold_time;
            const travelled_dis = rem_time * hold_time;

            if (travelled_dis > dis) {
                possible_times += 1;
            }
        }

        total *= possible_times;
    }

    return total;
}

fn part2(input: []const u8) !usize {
    _ = input;

    const time = 46828479;
    const dis = 347152214061471;

    var possible_times: usize = 0;

    for (0..time + 1) |hold_time| {
        const rem_time = time - hold_time;
        const travelled_dis = rem_time * hold_time;

        if (travelled_dis > dis) {
            possible_times += 1;
        }
    }

    return possible_times;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day06.txt");

    std.debug.print("~~ Day 06 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
