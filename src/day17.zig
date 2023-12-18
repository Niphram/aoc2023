const std = @import("std");
const util = @import("./util.zig");

const Grid = struct {
    const Self = @This();

    width: usize,
    height: usize,
    tiles: []const u8,

    fn parse(input: []const u8) Self {
        const width = std.mem.indexOfScalar(u8, input, '\n') orelse input.len;
        const height = (input.len + 1) / (width + 1);

        return Self{ .width = width, .height = height, .tiles = input };
    }

    fn get(self: Self, x: usize, y: usize) u8 {
        return self.tiles[y * (self.width + 1) ..][x];
    }

    fn step(self: Self, pos: Pos, dir: Dir) ?Pos {
        return switch (dir) {
            .Left => if (pos.x > 0) .{ .x = pos.x - 1, .y = pos.y } else null,
            .Up => if (pos.y > 0) .{ .x = pos.x, .y = pos.y - 1 } else null,
            .Right => if (pos.x < self.width - 1) .{ .x = pos.x + 1, .y = pos.y } else null,
            .Down => if (pos.y < self.height - 1) .{ .x = pos.x, .y = pos.y + 1 } else null,
            else => unreachable,
        };
    }
};

const Pos = struct {
    x: usize,
    y: usize,

    const ZERO = Pos{ .x = 0, .y = 0 };
};

const Dir = enum {
    Up,
    Right,
    Down,
    Left,

    None,

    fn turn(self: @This()) [2]Dir {
        return switch (self) {
            .Up, .Down => [_]Dir{ .Left, .Right },
            .Left, .Right => [_]Dir{ .Up, .Down },
            // Special case for starting node
            else => [_]Dir{ .Right, .Down },
        };
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = Grid.parse(input);

    const Candidate = struct {
        heat_loss: usize,
        position: Pos,
        direction: Dir,

        pub fn compareHeatLoss(context: void, a: @This(), b: @This()) std.math.Order {
            _ = context;
            return std.math.order(a.heat_loss, b.heat_loss);
        }
    };

    const Seen = struct {
        position: Pos,
        direction: Dir,
    };

    var candidates = std.PriorityQueue(Candidate, void, Candidate.compareHeatLoss).init(allocator, {});
    defer candidates.deinit();

    var seen = std.AutoHashMap(Seen, void).init(allocator);
    defer seen.deinit();

    //

    try candidates.add(.{ .heat_loss = 0, .position = Pos.ZERO, .direction = .None });

    while (candidates.removeOrNull()) |candidate| {
        const heat_loss = candidate.heat_loss;
        const pos = candidate.position;
        const dir = candidate.direction;

        // Check if the end was reached
        if (pos.x == grid.width - 1 and pos.y == grid.height - 1) {
            return heat_loss;
        }

        // Insert into seen and skip if already seen
        if (try seen.fetchPut(Seen{ .position = pos, .direction = dir }, {})) |_| {
            continue;
        }

        for (dir.turn()) |new_dir| {
            var new_heat_loss = heat_loss;
            var new_pos = pos;

            for (0..3) |_| {
                if (grid.step(new_pos, new_dir)) |p| {
                    new_pos = p;
                    new_heat_loss += grid.get(p.x, p.y) - '0';
                    try candidates.add(.{ .heat_loss = new_heat_loss, .position = new_pos, .direction = new_dir });
                } else break;
            }
        }
    }

    unreachable;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = Grid.parse(input);

    const Candidate = struct {
        heat_loss: usize,
        position: Pos,
        direction: Dir,

        pub fn compareHeatLoss(context: void, a: @This(), b: @This()) std.math.Order {
            _ = context;
            return std.math.order(a.heat_loss, b.heat_loss);
        }
    };

    const Seen = struct {
        position: Pos,
        direction: Dir,
    };

    var candidates = std.PriorityQueue(Candidate, void, Candidate.compareHeatLoss).init(allocator, {});
    defer candidates.deinit();

    var seen = std.AutoHashMap(Seen, void).init(allocator);
    defer seen.deinit();

    //

    try candidates.add(.{ .heat_loss = 0, .position = Pos.ZERO, .direction = .None });

    while (candidates.removeOrNull()) |candidate| {
        const heat_loss = candidate.heat_loss;
        const pos = candidate.position;
        const dir = candidate.direction;

        // Check if the end was reached
        if (pos.x == grid.width - 1 and pos.y == grid.height - 1) {
            return heat_loss;
        }

        // Insert into seen and skip if already seen
        if (try seen.fetchPut(Seen{ .position = pos, .direction = dir }, {})) |_| {
            continue;
        }

        for (dir.turn()) |new_dir| {
            var new_heat_loss = heat_loss;
            var new_pos = pos;

            const MIN_STEPS = 4;
            const MAX_STEPS = 10;

            for (0..MAX_STEPS) |step| {
                if (grid.step(new_pos, new_dir)) |p| {
                    new_pos = p;
                    new_heat_loss += grid.get(p.x, p.y) - '0';

                    if (step + 1 >= MIN_STEPS) {
                        try candidates.add(.{ .heat_loss = new_heat_loss, .position = new_pos, .direction = new_dir });
                    }
                } else break;
            }
        }
    }

    unreachable;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day17.txt");

    std.debug.print("~~ Day 17 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
