const std = @import("std");

var NUMBERS = [_][]const u8{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" };

fn part1(input: []const u8) usize {
    var total: usize = 0;
    var readIter = std.mem.tokenize(u8, input, "\n");

    while (readIter.next()) |line| {
        var firstNumberMinIndex: usize = std.math.maxInt(usize);
        var firstNumber: usize = 0;
        var secondNumberMaxIndex: usize = 0;
        var secondNumber: usize = 0;

        for (NUMBERS[10..], 0..) |numberSlice, k| {
            if (std.mem.indexOf(u8, line, numberSlice)) |foundIndex| {
                if (foundIndex < firstNumberMinIndex) {
                    firstNumberMinIndex = foundIndex;
                    firstNumber = k % 10;
                }
            }

            if (std.mem.lastIndexOf(u8, line, numberSlice)) |foundIndex| {
                if (foundIndex >= secondNumberMaxIndex) {
                    secondNumberMaxIndex = foundIndex;
                    secondNumber = k % 10;
                }
            }
        }

        total += firstNumber * 10 + secondNumber;
    }

    return total;
}

fn part2(input: []const u8) usize {
    var total: usize = 0;
    var readIter = std.mem.tokenize(u8, input, "\n");

    while (readIter.next()) |line| {
        var firstNumberMinIndex: usize = std.math.maxInt(usize);
        var firstNumber: usize = 0;
        var secondNumberMaxIndex: usize = 0;
        var secondNumber: usize = 0;

        for (NUMBERS, 0..) |numberSlice, k| {
            if (std.mem.indexOf(u8, line, numberSlice)) |foundIndex| {
                if (foundIndex < firstNumberMinIndex) {
                    firstNumberMinIndex = foundIndex;
                    firstNumber = k % 10;
                }
            }

            if (std.mem.lastIndexOf(u8, line, numberSlice)) |foundIndex| {
                if (foundIndex >= secondNumberMaxIndex) {
                    secondNumberMaxIndex = foundIndex;
                    secondNumber = k % 10;
                }
            }
        }

        total += firstNumber * 10 + secondNumber;
    }

    return total;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day01.txt");

    std.debug.print("Part 1: {}\n", .{part1(content)});
    std.debug.print("Part 2: {}\n", .{part2(content)});
}
