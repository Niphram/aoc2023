const std = @import("std");
const util = @import("./util.zig");

fn extrapolateForwards(input: []isize) isize {
    const steps: usize = for (0..input.len) |start| {
        // Take remaining numbers
        var current_range = input[0 .. input.len - start];

        // Check if only zeroes remain
        if (std.mem.allEqual(isize, current_range, 0)) {
            break start;
        }

        // Calculate all differences
        for (0..current_range.len - 1) |i| {
            current_range[i] = current_range[i + 1] - current_range[i];
        }
    } else unreachable;

    var prediction: isize = 0;

    // Extrapolate next number by summing last numbers of every step
    for (0..steps) |step| {
        prediction += input[input.len - step - 1];
    }

    return prediction;
}

fn extrapolateBackwards(input: []isize) isize {
    const steps: usize = for (0..input.len) |start| {
        // Take remaining numbers
        var current_range = input[start..];

        // Check if only zeroes remain
        if (std.mem.allEqual(isize, current_range, 0)) {
            break start;
        }

        // Calculate all differences
        for (1..current_range.len) |i| {
            const idx = current_range.len - i;
            current_range[idx] = current_range[idx] - current_range[idx - 1];
        }
    } else unreachable;

    var prediction: isize = 0;

    // Calculate predicted number
    for (0..steps) |step| {
        const idx = steps - step - 1;
        prediction = 0 - prediction + input[idx];
    }

    return prediction;
}

fn part1(input: []const u8) !isize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var total: isize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var readings = std.ArrayList(isize).init(allocator);
        defer readings.deinit();

        var reading_iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (reading_iter.next()) |reading| {
            try readings.append(try std.fmt.parseInt(isize, reading, 10));
        }

        total += extrapolateForwards(readings.items);
    }

    return total;
}

fn part2(input: []const u8) !isize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var total: isize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var readings = std.ArrayList(isize).init(allocator);
        defer readings.deinit();

        var reading_iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (reading_iter.next()) |reading| {
            try readings.append(try std.fmt.parseInt(isize, reading, 10));
        }

        total += extrapolateBackwards(readings.items);
    }

    return total;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day09.txt");

    std.debug.print("~~ Day 09 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
