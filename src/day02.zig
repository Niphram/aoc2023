const std = @import("std");

// Struct to store amounts of colors
const ColorCount = struct {
    red: usize = 0,
    green: usize = 0,
    blue: usize = 0,
};

fn part1(input: []const u8) !usize {
    var idSum: usize = 0;

    // Limits for each color
    const COLOR_LIMITS = ColorCount{ .red = 12, .green = 13, .blue = 14 };

    // Iterate through all lines
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    var game: usize = 1;
    gameloop: while (linesIter.next()) |line| : (game += 1) {
        // Find beginning of game data
        const startOfData = std.mem.indexOfScalar(u8, line, ':').? + 2;

        // Iterate through the pulls
        var pulls = std.mem.splitSequence(u8, line[startOfData..], "; ");
        while (pulls.next()) |pull| {

            // Iterate through different block pulls
            var blocks = std.mem.splitSequence(u8, pull, ", ");
            while (blocks.next()) |block| {

                // Split pull into <count> <color>
                const space = std.mem.indexOf(u8, block, " ").?;
                const count = try std.fmt.parseInt(i32, block[0..space], 10);
                const color = block[space + 1 ..];

                // Compiletime comparison to struct fields
                inline for (std.meta.fields(@TypeOf(COLOR_LIMITS))) |field| {
                    if (std.mem.eql(u8, color, field.name)) {

                        // If count is higher than limit, skip this game
                        if (count > @field(COLOR_LIMITS, field.name)) {
                            continue :gameloop;
                        }
                    }
                }
            }
        }

        // Update sum of valid game IDs
        idSum += game;
    }

    return idSum;
}

fn part2(input: []const u8) !usize {
    var idSum: usize = 0;

    // Iterate through lines
    var game: usize = 1;
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    while (linesIter.next()) |line| : (game += 1) {

        // Find start of game data
        const startOfData = std.mem.indexOfScalar(u8, line, ':').? + 2;

        // Keep track of color counts
        var counts = ColorCount{};

        // Iterate through pulls
        var pulls = std.mem.splitSequence(u8, line[startOfData..], "; ");
        while (pulls.next()) |pull| {

            // Iterate through blocks
            var blocks = std.mem.splitSequence(u8, pull, ", ");
            while (blocks.next()) |block| {

                // Split pull into <count> <color>
                const space = std.mem.indexOf(u8, block, " ").?;
                const count = try std.fmt.parseInt(usize, block[0..space], 10);
                const color = block[space + 1 ..];

                // Update maximums based on color
                inline for (std.meta.fields(ColorCount)) |field| {
                    if (std.mem.eql(u8, color, field.name)) {
                        @field(counts, field.name) = @max(@field(counts, field.name), count);
                    }
                }
            }
        }

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
