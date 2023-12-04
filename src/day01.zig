const std = @import("std");
const util = @import("util.zig");

fn part1(input: []const u8) usize {
    var calibrationSum: usize = 0;

    // Split input into lines
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        var firstDigit: ?u8 = null;
        var lastDigit: ?u8 = null;

        // Iterate through every character
        for (line) |char| {

            // Check if character is a digit
            if (std.ascii.isDigit(char)) {

                // Update first digit, if it is still null
                if (firstDigit == null) {
                    firstDigit = char - '0';
                }

                // Always update last digit
                lastDigit = char - '0';
            }
        }

        // Update total with calibration value
        calibrationSum += firstDigit.? * 10 + lastDigit.?;
    }

    return calibrationSum;
}

fn part2(input: []const u8) usize {
    var calibrationSum: usize = 0;

    // All possible numbers as strings
    const NUMBERS = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "1", "2", "3", "4", "5", "6", "7", "8", "9" };

    // Split input into lines
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        const first = util.findFirstOf(u8, line, &NUMBERS).? % 9 + 1;
        const last = util.findLastOf(u8, line, &NUMBERS).? % 9 + 1;

        // Update total with calibration value
        calibrationSum += first * 10 + last;
    }

    return calibrationSum;
}

pub fn main() !void {
    const input = comptime @embedFile("data/day01.txt");

    std.debug.print("~~ Day 01 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{part1(input)});
    std.debug.print("Part 2: {}\n", .{part2(input)});
}
