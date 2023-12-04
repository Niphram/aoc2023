const std = @import("std");

// Struct to store amounts of colors
const ColorCount = struct {
    red: usize = 0,
    green: usize = 0,
    blue: usize = 0,
};

fn maxColors(game: []const u8) !ColorCount {
    const util = @import("./util.zig");

    // Get game data
    const game_data = util.splitSequenceOnce(u8, game, ": ")[1];

    var max_colors = ColorCount{};

    // Iterate through the pulls
    var pull_iter = std.mem.splitSequence(u8, game_data, "; ");
    while (pull_iter.next()) |pull| {

        // Iterate through the blocks
        var block_iter = std.mem.splitSequence(u8, pull, ", ");
        while (block_iter.next()) |block| {

            // Get block color and count
            const count_s, const color = util.splitScalarOnce(u8, block, ' ');
            const count = try std.fmt.parseUnsigned(usize, count_s, 10);

            // Update maximums
            inline for (std.meta.fields(ColorCount)) |field| {
                if (std.mem.eql(u8, color, field.name)) {
                    const countField = &@field(max_colors, field.name);
                    countField.* = @max(countField.*, count);
                }
            }
        }
    }

    return max_colors;
}

fn part1(input: []const u8) !usize {
    var id_sum: usize = 0;

    // Limits for each color
    const COLOR_LIMITS = ColorCount{ .red = 12, .green = 13, .blue = 14 };

    // Iterate through lines
    var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var game_id: usize = 1;
    while (lines_iter.next()) |line| : (game_id += 1) {
        // Get maximum counts
        const counts = try maxColors(line);

        // Check if counts fall below limit and update sum of IDs
        if (counts.red <= COLOR_LIMITS.red and counts.green <= COLOR_LIMITS.green and counts.blue <= COLOR_LIMITS.blue) {
            id_sum += game_id;
        }
    }

    return id_sum;
}

fn part2(input: []const u8) !usize {
    var idSum: usize = 0;

    // Iterate through lines
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        // Get maximum counts
        const counts = try maxColors(line);

        // Update total sum
        idSum += counts.red * counts.green * counts.blue;
    }

    return idSum;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day02.txt");

    std.debug.print("~~ Day 02 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
