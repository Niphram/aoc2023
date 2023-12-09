const std = @import("std");
const util = @import("./util.zig");

fn Hand(comptime card_order: []const u8, comptime jokers: []const u8) type {
    return struct {
        const Self = @This();

        const suite_size = card_order.len;
        const non_jokers = util.removeSet(u8, card_order, jokers);

        bid: usize,
        rank: usize,

        fn sort(context: void, a: Self, b: Self) bool {
            _ = context;
            return a.rank < b.rank;
        }

        fn parse(input: []const u8) !Self {
            const cards, const bid_s = util.splitScalarOnce(u8, input, ' ');
            const bid = try std.fmt.parseInt(usize, bid_s, 10);

            // Can add the number of jokers to the highest multiple,
            // since the rules will always favor higher multiples
            const max_multiples =
                util.maxMultiplesOfAny(u8, cards, &non_jokers) +
                util.countOfAny(u8, cards, jokers);

            const unique_count = util.countUniquesOfAny(u8, cards, &non_jokers);

            // By subtracting the number of unique cards from the highest multiple,
            // you get a unique value for every hand type
            var rank: usize = switch (4 + max_multiples - unique_count) {
                9, 8 => 6, // five of a kind
                6 => 5, // four of a kind
                5 => 4, // full house
                4 => 3, // three of a kind
                3 => 2, // two pairs
                2 => 1, // pair
                0 => 0, // high card
                else => unreachable,
            };

            // Pack card values into the rank to give every possible hand a unique value
            for (cards) |card| {
                rank *= suite_size;
                rank += std.mem.indexOfScalar(u8, card_order, card).?;
            }

            return Self{ .bid = bid, .rank = rank };
        }
    };
}

fn playGame(comptime HandType: type, input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var hands = std.ArrayList(HandType).init(allocator);
    defer hands.deinit();

    var hand_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (hand_iter.next()) |hand| {
        try hands.append(try HandType.parse(hand));
    }

    std.mem.sort(HandType, hands.items, {}, HandType.sort);

    var total_winnings: usize = 0;
    for (hands.items, 1..) |hand, place| {
        total_winnings += place * hand.bid;
    }

    return total_winnings;
}

fn part1(input: []const u8) !usize {
    // Normal card order, no jokers
    const NormalHand = Hand("23456789TJQKA", "");

    return try playGame(NormalHand, input);
}

fn part2(input: []const u8) !usize {
    // Jacks are jokers and ranked lowest
    const JokerHand = Hand("J23456789TQKA", "J");

    return try playGame(JokerHand, input);
}

pub fn main() !void {
    const content = comptime @embedFile("data/day07.txt");

    std.debug.print("~~ Day 07 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
