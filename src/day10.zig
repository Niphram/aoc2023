const std = @import("std");
const util = @import("./util.zig");

const Pos = struct {
    const Self = @This();

    const Dir = enum { Up, Right, Down, Left };

    x: usize,
    y: usize,

    fn step(self: Self, dir: Dir) Self {
        return switch (dir) {
            .Up => .{ .x = self.x, .y = self.y - 1 },
            .Right => .{ .x = self.x + 1, .y = self.y },
            .Down => .{ .x = self.x, .y = self.y + 1 },
            .Left => .{ .x = self.x - 1, .y = self.y },
        };
    }
};

const PipeGrid = struct {
    const Self = @This();

    const Pipe = packed struct {
        loop: bool = false,
        type: u7,
    };

    allocator: std.mem.Allocator,

    width: usize,
    height: usize,

    start: Pos,

    tiles: []Pipe,

    fn idx(self: Self, pos: Pos) usize {
        return pos.x + pos.y * self.width;
    }

    // Traverses the loop and returns the length
    // Also marks the
    fn calculateLoop(self: *Self) usize {
        var step: usize = 0;

        var position = self.start;
        var direction = Pos.Dir.Up;

        return while (true) {
            const pipe = &self.tiles[self.idx(position)];

            // If were on a tile that is part of the loop, stop searching
            if (pipe.loop) break step;

            // Mark tile as part of the loop
            pipe.*.loop = true;

            // Decide on new direction based on the last direction and the pipe
            direction = switch (pipe.type) {
                '|' => if (direction == .Up) .Up else .Down,
                '-' => if (direction == .Right) .Right else .Left,
                '7' => if (direction == .Up) .Left else .Down,
                'J' => if (direction == .Down) .Left else .Up,
                'L' => if (direction == .Down) .Right else .Up,
                'F' => if (direction == .Up) .Right else .Down,
                else => unreachable,
            };

            step += 1;
            position = position.step(direction);
        };
    }

    fn guessStartPipe(self: Self) Pipe {
        const start = self.start;
        const grid = self.tiles;

        const pipes = "|-LJF7";
        // Bitset of pipes (order is inverted)
        const MaskInt = std.meta.Int(.unsigned, pipes.len);
        var possibilities: MaskInt = std.math.maxInt(MaskInt);

        const indexOfScalar = std.mem.indexOfScalar;

        // Top
        if (start.y == 0 or indexOfScalar(u8, "|F7", grid[self.idx(start.step(.Up))].type) == null) {
            possibilities &= 0b110010; // Start can't be '|', 'L' or 'J'
        }

        // Right
        if (start.x == self.width - 1 or indexOfScalar(u8, "-J7", grid[self.idx(start.step(.Right))].type) == null) {
            possibilities &= 0b101001; // Start can't be '-', 'L' or 'F'
        }

        // Bottom
        if (start.y == self.height - 1 or indexOfScalar(u8, "|LJ", grid[self.idx(start.step(.Down))].type) == null) {
            possibilities &= 0b001110; // Start can't be '|', 'F' or '7'
        }

        // Left
        if (start.x == 0 or indexOfScalar(u8, "-LF", grid[self.idx(start.step(.Left))].type) == null) {
            possibilities &= 0b010101; // Start can't be '-', 'J' or '7'
        }

        std.debug.assert(@popCount(possibilities) == 1);

        return .{ .type = @intCast(pipes[@ctz(possibilities)]) };
    }

    // Assumes a newline at the end of the input
    fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        const width = std.mem.indexOfScalar(u8, input, '\n').?;
        const height = (input.len + 1) / width;

        const start_idx = std.mem.indexOfScalar(u8, input, 'S').?;
        const start = Pos{ .x = @mod(start_idx, width + 1), .y = start_idx / (width + 1) };

        // Allocate our own buffer so that we can modify it
        const tiles = try allocator.alloc(Pipe, width * height);
        {
            var i: usize = 0;
            for (input) |tile| {
                if (tile != '\n') {
                    tiles[i] = .{ .type = @intCast(tile) };
                    i += 1;
                }
            }
        }

        var self = Self{
            .allocator = allocator,
            .width = width,
            .height = height,
            .start = start,
            .tiles = tiles,
        };

        // Replace starting node with correct pipe
        tiles[self.idx(start)] = .{ .type = self.guessStartPipe().type };

        return self;
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.tiles);
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try PipeGrid.parse(allocator, input);
    defer grid.deinit();

    return grid.calculateLoop() / 2;
}

// Uses a scanline approach to calculate the area inside the loop.
// Scan the grid from left-right/top-bottom.
// Use a boolean to keep track of inside/outside.
fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try PipeGrid.parse(allocator, input);
    defer grid.deinit();

    // Calculate the loop to mark the tiles
    _ = grid.calculateLoop();

    var encased_area: usize = 0;
    var in_loop = false;
    for (grid.tiles) |tile| {
        // Increase encased area if tile is not the loop itself
        // and were currently in the loop
        if (in_loop and !tile.loop) {
            encased_area += 1;
        }

        // If the tile is part of the loop
        if (tile.loop) {
            // Toggle in_loop if it is '|', 'F' or '7'
            inline for ("|F7") |pipe| {
                if (tile.type == pipe) {
                    in_loop = !in_loop;
                }
            }
        }
    }

    return encased_area;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day10.txt");

    std.debug.print("~~ Day 10 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
