const std = @import("std");
const util = @import("./util.zig");

const Boat = struct { speed: usize = 0 };

const CARDS: []const u8 = "AKQJT98765432";

const Hand = struct {
    const Self = @This();

    cards: []const u8,
    bid: usize,

    fn sort(context: void, a: Self, b: Self) bool {
        _ = context;
        const a_type = a.rank();
        const b_type = b.rank();

        if (a_type == b_type) {
            for (a.cards, b.cards) |a_card, b_card| {
                if (a_card == b_card) continue;

                const a_card_idx = std.mem.indexOfScalar(u8, CARDS, a_card).?;
                const b_card_idx = std.mem.indexOfScalar(u8, CARDS, b_card).?;

                return a_card_idx < b_card_idx;
            }
        }

        return a_type > b_type;
    }

    fn rank(self: Self) usize {
        var max_same_count: usize = 0;
        inline for (0..CARDS.len) |i| {
            const count = std.mem.count(u8, self.cards, CARDS[i .. i + 1]);
            max_same_count = @max(max_same_count, count);
        }

        if (max_same_count == 5) {
            return 6; // Five of a kind
        }

        if (max_same_count == 4) {
            return 5; // Four of a kind
        }

        if (max_same_count == 3) {
            inline for (0..CARDS.len) |i| {
                if (std.mem.count(u8, self.cards, CARDS[i .. i + 1]) == 2) {
                    return 4; // Full House
                }
            }
        }

        if (max_same_count == 3) {
            return 3; // Three of a kind
        }

        if (max_same_count == 2) {
            var count: usize = 0;
            inline for (0..CARDS.len) |i| {
                if (std.mem.count(u8, self.cards, CARDS[i .. i + 1]) == 2) {
                    count += 1;
                }
            }
            if (count == 2) {
                return 2; // Two pairs
            }
        }

        if (max_same_count == 2) {
            return 1; // One Pair
        }

        return 0;
    }
};

const Card2 = enum { Ace, King, Queen, Ten, Nine, Eight, Seven, Six, Five, Four, Three, Two, Joker };
const HandType = enum(usize) { FiveOfAKind = 6, FourOfAKind = 5, FullHouse = 4, ThreeOfAKind = 3, TwoPairs = 2, Pair = 1, HighCard = 0 };

const CARDS2: []const u8 = "AKQT98765432J";
const Hand2 = struct {
    const Self = @This();

    cards: [5]Card2,
    bid: usize,
    hand_score: HandType,

    fn parse(input: []const u8) !Self {
        const cards_s, const bid_s = util.splitScalarOnce(u8, input, ' ');
        const bid = try std.fmt.parseInt(usize, bid_s, 10);

        var card_values: [5]Card2 = undefined;
        for (0..5) |i| {
            const card_val = std.mem.indexOfScalar(u8, CARDS2, cards_s[i]).?;
            card_values[i] = @enumFromInt(card_val);
        }

        const joker_num = std.mem.count(Card2, card_values[0..], &[_]Card2{Card2.Joker});

        const highest_hand: HandType = blk: {
            var max_same_count: usize = 0;
            inline for (0..12) |i| {
                const count = std.mem.count(Card2, card_values[0..], &[_]Card2{@enumFromInt(i)}) + joker_num;
                max_same_count = @max(max_same_count, count);
            }

            if (max_same_count == 5) {
                break :blk HandType.FiveOfAKind;
            }

            if (max_same_count == 4) {
                break :blk HandType.FourOfAKind; // Four of a kind
            }

            if (max_same_count == 3) {
                inline for (0..CARDS2.len - 1) |i| {
                    if (std.mem.count(Card2, &card_values, &[_]Card2{@enumFromInt(i)}) >= 2) {
                        for (i + 1..CARDS2.len - 1) |j| {
                            if (std.mem.count(Card2, &card_values, &[_]Card2{@enumFromInt(j)}) >= 2) {
                                break :blk HandType.FullHouse; // Full House
                            }
                        }
                    }
                }
            }

            if (max_same_count == 3) {
                break :blk HandType.ThreeOfAKind; // Three of a kind
            }

            if (max_same_count == 2) {
                var count: usize = 0;
                inline for (0..CARDS2.len - 1) |i| {
                    if (std.mem.count(Card2, &card_values, &[_]Card2{@enumFromInt(i)}) == 2) {
                        count += 1;
                    }
                }
                if (count == 2) {
                    break :blk HandType.TwoPairs; // Two pairs
                }
            }

            if (max_same_count == 2) {
                break :blk HandType.Pair; // One Pair
            }

            break :blk HandType.HighCard;
        };

        return Self{ .bid = bid, .cards = card_values, .hand_score = highest_hand };
    }

    fn sort(context: void, a: Self, b: Self) bool {
        _ = context;

        if (a.hand_score == b.hand_score) {
            for (a.cards, b.cards) |a_card, b_card| {
                if (a_card == b_card) continue;

                return @intFromEnum(a_card) < @intFromEnum(b_card);
            }

            return false;
        }

        return @intFromEnum(a.hand_score) > @intFromEnum(b.hand_score);
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var hands = std.ArrayList(Hand).init(allocator);
    defer hands.deinit();

    var hand_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (hand_iter.next()) |hand| {
        const cards, const bid_s = util.splitScalarOnce(u8, hand, ' ');
        const bid = try std.fmt.parseInt(usize, bid_s, 10);
        try hands.append(Hand{ .cards = cards[0..5], .bid = bid });
    }

    std.mem.sort(Hand, hands.items, {}, Hand.sort);

    var total_winnings: usize = 0;
    for (hands.items, 0..) |hand, place| {
        const rank = hands.items.len - place;
        total_winnings += rank * hand.bid;
    }

    return total_winnings;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var hands = std.ArrayList(Hand2).init(allocator);
    defer hands.deinit();

    var hand_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (hand_iter.next()) |hand| {
        try hands.append(try Hand2.parse(hand));
    }

    std.mem.sort(Hand2, hands.items, {}, Hand2.sort);

    for (hands.items, 0..) |hand, i| {
        std.debug.print("{:4} Cards: ", .{i});
        for (hand.cards) |card| {
            std.debug.print("{s:5} ", .{@tagName(card)});
        }

        std.debug.print("| {s} Bid {}\n", .{ @tagName(hand.hand_score), hand.bid });
    }

    var total_winnings: usize = 0;
    for (hands.items, 0..) |hand, place| {
        const rank = hands.items.len - place;
        total_winnings += rank * hand.bid;
    }

    return total_winnings;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day07.txt");

    std.debug.print("~~ Day 07 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
