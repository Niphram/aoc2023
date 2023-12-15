const std = @import("std");
const util = @import("./util.zig");

fn holidayAsciiStringHelper(input: []const u8) u8 {
    var state: u8 = 0;
    for (input) |c| {
        state = @truncate((@as(usize, state) + c) * 17);
    }
    return state;
}

const HASHMAP = struct {
    const Self = @This();

    const Lens = struct {
        label: []const u8,
        strength: u8,
    };

    boxes: [256]std.ArrayList(Lens),

    fn init(allocator: std.mem.Allocator) Self {
        var boxes: [256]std.ArrayList(Lens) = undefined;

        for (&boxes) |*box| {
            box.* = std.ArrayList(Lens).init(allocator);
        }

        return Self{ .boxes = boxes };
    }

    fn executeStep(self: *Self, step: []const u8) !void {
        const op_idx = std.mem.indexOfAny(u8, step, "=-").?;

        const label = step[0..op_idx];
        const box_id = holidayAsciiStringHelper(label);

        switch (step[op_idx]) {
            '=' => {
                const strength = step[op_idx + 1] - '0';
                var box = &self.boxes[box_id];

                // Try to find lens with label
                for (box.items) |*lens| {
                    if (std.mem.eql(u8, lens.label, label)) {
                        // Update focus strength
                        lens.*.strength = strength;
                        break;
                    }
                } else {
                    // Append new lens
                    try box.append(Lens{ .label = label, .strength = strength });
                }
            },
            '-' => {
                // Find lens and remove
                for (self.boxes[box_id].items, 0..) |lens, i| {
                    if (std.mem.eql(u8, lens.label, label)) {
                        _ = self.boxes[box_id].orderedRemove(i);
                        break;
                    }
                }
            },
            else => unreachable,
        }
    }

    fn focusingPower(self: Self) usize {
        var total: usize = 0;

        for (self.boxes, 1..) |box, box_idx| {
            for (box.items, 1..) |lens, lens_idx| {
                total += box_idx * lens_idx * lens.strength;
            }
        }

        return total;
    }

    fn deinit(self: Self) void {
        for (self.boxes) |box| {
            box.deinit();
        }
    }
};

fn part1(input: []const u8) !usize {
    var total: usize = 0;

    var iter = std.mem.splitScalar(u8, input, ',');
    while (iter.next()) |step| {
        total += holidayAsciiStringHelper(step);
    }

    return total;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var hashmap = HASHMAP.init(allocator);
    defer hashmap.deinit();

    var iter = std.mem.splitScalar(u8, input, ',');
    while (iter.next()) |step| {
        try hashmap.executeStep(step);
    }

    return hashmap.focusingPower();
}

pub fn main() !void {
    const content = comptime @embedFile("data/day15.txt");

    std.debug.print("~~ Day 15 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
