const std = @import("std");
const util = @import("./util.zig");

const PipeGrid = struct {
    const Self = @This();

    const Pos = struct { x: isize, y: isize };

    const Pipe = struct {
        loop: bool = false,
        type: u8,
    };

    allocator: std.mem.Allocator,

    width: isize,
    height: isize,

    start: Pos,

    grid: []Pipe,

    fn idx(self: Self, x: isize, y: isize) usize {
        return @intCast(x + y * (self.width + 1));
    }

    fn getPos(self: Self, x: isize, y: isize) Pipe {
        if (x < 0 or
            x >= self.width or
            y < 0 or
            y >= self.height)
        {
            return .{ .type = '.' };
        }

        return self.grid[self.idx(x, y)];
    }

    fn setPos(self: *Self, x: isize, y: isize, val: Pipe) void {
        if (x < 0 or x >= self.width) return;
        if (y < 0 or y >= self.height) return;

        self.grid[self.idx(x, y)] = val;
    }

    // Traverses the loop and returns the length
    // Also marks the
    fn calculateLoop(self: *Self) usize {
        var step: usize = 0;

        const Dir = enum { Up, Right, Down, Left };

        const starting_pipe = self.guessStartPipe();

        var pipe = starting_pipe;
        var current_pos = self.start;
        var last_dir: Dir = .Up;

        while (true) : ({
            step += 1;
            pipe = self.getPos(current_pos.x, current_pos.y);

            var ended = false;
            if (pipe.type == 'S') {
                pipe = starting_pipe;
                ended = true;
            }

            // Mark loop
            self.setPos(current_pos.x, current_pos.y, .{ .loop = true, .type = pipe.type });

            if (ended) {
                break;
            }
        }) {
            last_dir = switch (pipe.type) {
                '|' => if (last_dir == .Up) .Up else .Down,
                '-' => if (last_dir == .Right) .Right else .Left,
                '7' => if (last_dir == .Up) .Left else .Down,
                'J' => if (last_dir == .Down) .Left else .Up,
                'L' => if (last_dir == .Down) .Right else .Up,
                'F' => if (last_dir == .Up) .Right else .Down,
                else => unreachable,
            };

            current_pos = switch (last_dir) {
                .Up => Pos{ .x = current_pos.x, .y = current_pos.y - 1 },
                .Right => Pos{ .x = current_pos.x + 1, .y = current_pos.y },
                .Down => Pos{ .x = current_pos.x, .y = current_pos.y + 1 },
                .Left => Pos{ .x = current_pos.x - 1, .y = current_pos.y },
            };
        }

        return step;
    }

    fn guessStartPipe(self: Self) Pipe {
        const t = self.getPos(self.start.x, self.start.y - 1).type;
        const r = self.getPos(self.start.x + 1, self.start.y).type;
        const b = self.getPos(self.start.x, self.start.y + 1).type;
        const l = self.getPos(self.start.x - 1, self.start.y).type;

        const pipes = "|-LJF7";
        var possibilities = std.bit_set.StaticBitSet(pipes.len).initFull();

        // Top
        if (std.mem.indexOfScalar(u8, "|F7", t) == null) {
            possibilities.unset(0); // |
            possibilities.unset(2); // L
            possibilities.unset(3); // J
        }

        // Right
        if (std.mem.indexOfScalar(u8, "-J7", r) == null) {
            possibilities.unset(1); // -
            possibilities.unset(2); // L
            possibilities.unset(4); // F
        }

        // Bottom
        if (std.mem.indexOfScalar(u8, "|LJ", b) == null) {
            possibilities.unset(0); // |
            possibilities.unset(4); // F
            possibilities.unset(5); // 7
        }

        // Left
        if (std.mem.indexOfScalar(u8, "-LF", l) == null) {
            possibilities.unset(1); // -
            possibilities.unset(3); // J
            possibilities.unset(5); // 7
        }

        std.debug.assert(possibilities.count() == 1);

        return .{ .type = pipes[possibilities.findFirstSet().?] };
    }

    // Assumes a newline at the end of the input
    fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        const width: isize = @intCast(std.mem.indexOfScalar(u8, input, '\n').?);
        const height: isize = @intCast(std.mem.count(u8, input, "\n"));

        const start_idx: isize = @intCast(std.mem.indexOfScalar(u8, input, 'S').?);
        const start = Pos{ .x = @mod(start_idx, width + 1), .y = @divFloor(start_idx, (width + 1)) };

        // Allocate our own buffer so that we can modify it
        const grid = try allocator.alloc(Pipe, input.len);
        for (input, 0..) |tile, i| {
            grid[i] = .{ .type = tile };
        }

        return Self{
            .allocator = allocator,
            .width = width,
            .height = height,
            .start = start,
            .grid = grid,
        };
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.grid);
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
    for (grid.grid) |tile| {
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
