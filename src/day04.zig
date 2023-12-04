const std = @import("std");

fn calculate_card(card: []const u8) !usize {
    const splitSequenceOnce = @import("./util.zig").splitSequenceOnce;

    const card_data = splitSequenceOnce(u8, card, ": ")[1];
    const win_numbers, const our_numbers = splitSequenceOnce(u8, card_data, " | ");

    var win_iter = std.mem.tokenizeScalar(u8, win_numbers, ' ');
    var our_iter = std.mem.tokenizeScalar(u8, our_numbers, ' ');

    var win_count: usize = 0;

    while (win_iter.next()) |win_s| {
        our_iter.reset();

        while (our_iter.next()) |our_s| {
            const win_n = try std.fmt.parseInt(i32, win_s, 10);
            const our_n = try std.fmt.parseInt(i32, our_s, 10);

            if (win_n == our_n) {
                win_count += 1;
            }
        }
    }

    return win_count;
}

fn part1(input: []const u8) !usize {
    var total: usize = 0;

    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        const wins = try calculate_card(line);

        if (wins > 0) {
            total += std.math.pow(usize, 2, wins - 1);
        }
    }

    return total;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Card = struct { count: usize = 1, wins: usize = 0 };

    var cards = std.ArrayList(Card).init(allocator);
    defer cards.deinit();

    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        const wins = try calculate_card(line);

        try cards.append(Card{ .wins = wins });
    }

    var total: usize = 0;

    for (cards.items, 0..) |card, card_idx| {
        total += card.count;

        const next_cards_idx = card_idx + 1;
        const capped_wins = @min(next_cards_idx + card.wins, cards.items.len);
        const won_cards = cards.items[next_cards_idx..capped_wins];

        for (won_cards) |*won_card| {
            won_card.*.count += card.count;
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
