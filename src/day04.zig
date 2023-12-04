const std = @import("std");

fn part1(input: []const u8) !usize {
    // Find numbers
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');

    var total: usize = 0;

    while (linesIter.next()) |line| {
        const data_start = std.mem.indexOfScalar(u8, line, ':').? + 2;

        const data = line[data_start..];

        const seperator = std.mem.indexOfScalar(u8, data, '|').?;
        const winning_numbers = data[0 .. seperator - 1];
        const my_numbers = data[seperator + 2 ..];
        var score: ?usize = null;

        var winning_iter = std.mem.tokenizeScalar(u8, winning_numbers, ' ');
        var numbers_iter = std.mem.tokenizeScalar(u8, my_numbers, ' ');
        while (winning_iter.next()) |win| {
            numbers_iter.reset();

            while (numbers_iter.next()) |number| {
                const winning = try std.fmt.parseInt(i32, win, 10);
                const my = try std.fmt.parseInt(i32, number, 10);

                if (winning == my) {
                    if (score) |*score_r| {
                        score_r.* *= 2;
                    } else {
                        score = 1;
                    }
                }
            }
        }

        if (score) |score_r| {
            total += score_r;
        }
    }

    return total;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const Card = struct { count: usize = 1, wins: usize = 0 };

    var winCounts = std.ArrayList(Card).init(allocator);
    defer winCounts.deinit();

    // Find numbers
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');

    var game_idx: usize = 0;
    while (linesIter.next()) |line| : (game_idx += 1) {
        const data_start = std.mem.indexOfScalar(u8, line, ':').? + 2;

        const data = line[data_start..];

        const seperator = std.mem.indexOfScalar(u8, data, '|').?;
        const winning_numbers = data[0 .. seperator - 1];
        const my_numbers = data[seperator + 2 ..];

        var wins: usize = 0;

        var winning_iter = std.mem.tokenizeScalar(u8, winning_numbers, ' ');
        var numbers_iter = std.mem.tokenizeScalar(u8, my_numbers, ' ');
        while (winning_iter.next()) |win| {
            numbers_iter.reset();

            while (numbers_iter.next()) |number| {
                const winning = try std.fmt.parseInt(i32, win, 10);
                const my = try std.fmt.parseInt(i32, number, 10);

                if (winning == my) {
                    wins += 1;
                }
            }
        }

        try winCounts.append(Card{ .wins = wins });
    }

    var total: usize = 0;

    for (0..winCounts.items.len) |i| {
        total += winCounts.items[i].count;
        const wins = winCounts.items[i].wins;

        const max = @min(wins, winCounts.items.len - i - 1);

        for (0..max) |j| {
            const idx = i + j + 1;
            winCounts.items[idx].count += winCounts.items[i].count;
        }
    }

    return total;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day04.txt");

    std.debug.print("~~ Day 04 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
