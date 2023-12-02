const std = @import("std");

fn part1(input: []const u8) !usize {
    var total: usize = 0;
    var lines = std.mem.tokenize(u8, input, "\n");

    var game: usize = 0;
    gameloop: while (lines.next()) |line| {
        game += 1;

        const startOfData = std.mem.indexOfScalar(u8, line, ':').?;

        var pulls = std.mem.splitSequence(u8, line[(startOfData + 2)..], "; ");
        while (pulls.next()) |pull| {
            var blocks = std.mem.splitSequence(u8, pull, ", ");
            while (blocks.next()) |block| {
                const space = std.mem.indexOf(u8, block, " ").?;

                const count = try std.fmt.parseInt(i32, block[0..space], 10);
                const color = block[space + 1 ..];

                if (std.mem.eql(u8, color, "blue") and count > 14) {
                    continue :gameloop;
                } else if (std.mem.eql(u8, color, "red") and count > 12) {
                    continue :gameloop;
                } else if (std.mem.eql(u8, color, "green") and count > 13) {
                    continue :gameloop;
                }
            }
        }
        total += game;
    }

    return total;
}

fn part2(input: []const u8) !usize {
    var total: usize = 0;
    var lines = std.mem.tokenize(u8, input, "\n");

    var game: usize = 0;
    while (lines.next()) |line| {
        game += 1;

        const startOfData = std.mem.indexOfScalar(u8, line, ':').?;

        var minRed: usize = 0;
        var minBlue: usize = 0;
        var minGreen: usize = 0;

        var pulls = std.mem.splitSequence(u8, line[(startOfData + 2)..], "; ");
        while (pulls.next()) |pull| {
            var blocks = std.mem.splitSequence(u8, pull, ", ");
            while (blocks.next()) |block| {
                const space = std.mem.indexOf(u8, block, " ").?;

                const count = try std.fmt.parseInt(usize, block[0..space], 10);
                const color = block[space + 1 ..];

                if (std.mem.eql(u8, color, "blue")) {
                    minBlue = @max(minBlue, count);
                } else if (std.mem.eql(u8, color, "red")) {
                    minRed = @max(minRed, count);
                } else if (std.mem.eql(u8, color, "green")) {
                    minGreen = @max(minGreen, count);
                }
            }
        }
        total += minRed * minBlue * minGreen;
    }

    return total;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day02.txt");

    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
