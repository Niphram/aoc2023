const std = @import("std");

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
        // Keep track of the first and last number
        var firstNumberMinIndex: usize = std.math.maxInt(usize);
        var lastNumberMaxIndex: usize = 0;
        var firstNumber: ?usize = null;
        var lastNumber: ?usize = null;

        // Iterate through all number strings
        for (NUMBERS, 0..) |numberSlice, currentNumber| {
            // Find first number
            if (std.mem.indexOf(u8, line, numberSlice)) |idx| {
                if (idx < firstNumberMinIndex) {
                    firstNumberMinIndex = idx;
                    firstNumber = currentNumber % 9 + 1;
                }
            }

            // Find last number
            if (std.mem.lastIndexOf(u8, line, numberSlice)) |idx| {
                if (idx >= lastNumberMaxIndex) {
                    lastNumberMaxIndex = idx;
                    lastNumber = currentNumber % 9 + 1;
                }
            }
        }

        // Update total with calibration value
        calibrationSum += firstNumber.? * 10 + lastNumber.?;
    }

    return calibrationSum;
}

pub fn main() !void {
    const input = comptime @embedFile("data/day01.txt");

    std.debug.print("~~ Day 01 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{part1(input)});
    std.debug.print("Part 2: {}\n", .{part2(input)});
}
