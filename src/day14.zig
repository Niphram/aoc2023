const std = @import("std");
const util = @import("./util.zig");

const Grid = struct {
    const Self = @This();

    const Tile = enum(u8) { Rock = 'O', Wall = '#', None = '.' };

    const Dir = enum {
        Up,
        Right,
        Down,
        Left,

        fn rotateRight(self: Dir) Dir {
            return switch (self) {
                .Up => .Right,
                .Right => .Down,
                .Down => .Left,
                .Left => .Up,
            };
        }

        fn flip(self: Dir) Dir {
            return switch (self) {
                .Up => .Down,
                .Down => .Up,
                .Right => .Left,
                .Left => .Right,
            };
        }
    };

    const Pos = struct {
        x: usize,
        y: usize,

        fn step(self: Pos, dir: Dir, width: usize, height: usize) ?Pos {
            return switch (dir) {
                .Up => if (self.y > 0) Pos{ .x = self.x, .y = self.y - 1 } else null,
                .Right => if (self.x < width - 1) Pos{ .x = self.x + 1, .y = self.y } else null,
                .Down => if (self.y < height - 1) Pos{ .x = self.x, .y = self.y + 1 } else null,
                .Left => if (self.x > 0) Pos{ .x = self.x - 1, .y = self.y } else null,
            };
        }
    };

    width: usize,
    height: usize,
    tiles: []Tile,

    allocator: std.mem.Allocator,

    fn hash(self: Self) u64 {
        var h = std.hash.Wyhash.init(1000);
        h.update(std.mem.sliceAsBytes(self.tiles));
        return h.final();
    }

    fn print(self: Self) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                std.debug.print("{c}", .{@intFromEnum(self.get(x, y))});
            }
            std.debug.print("\n", .{});
        }
    }

    fn initParse(allocator: std.mem.Allocator, input: []const u8) !Self {
        const width = std.mem.indexOfScalar(u8, input, '\n') orelse input.len;
        const height = (input.len + 1) / (width + 1);

        const tiles = try allocator.alloc(Tile, width * height);

        var i: usize = 0;
        var line_iter = std.mem.splitScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            for (line) |c| {
                tiles[i] = @enumFromInt(c);
                i += 1;
            }
        }

        return .{
            .width = width,
            .height = height,
            .tiles = tiles,
            .allocator = allocator,
        };
    }

    fn roll2(self: *Self, dir: Dir) void {
        var corner_opt: ?Pos = switch (dir) {
            .Up => Pos{ .x = 0, .y = 0 },
            .Right => Pos{ .x = self.width - 1, .y = 0 },
            .Down => Pos{ .x = self.width - 1, .y = self.height - 1 },
            .Left => Pos{ .x = 0, .y = self.height - 1 },
        };

        while (corner_opt) |start| : (corner_opt = corner_opt.?.step(dir.rotateRight(), self.width, self.height)) {
            var current_opt: ?Pos = start;
            var free_pos: ?Pos = start;
            while (current_opt) |pos| : ({
                current_opt = current_opt.?.step(dir.flip(), self.width, self.height);
            }) {
                switch (self.get(pos.x, pos.y)) {
                    .None => {
                        if (free_pos == null) free_pos = pos;
                    },
                    .Rock => {
                        if (free_pos) |free| {
                            self.set(pos.x, pos.y, .None);
                            self.set(free.x, free.y, .Rock);
                            free_pos = free.step(dir.flip(), self.width, self.height);
                        }
                    },
                    .Wall => {
                        free_pos = null;
                    },
                }
            }
        }
    }

    fn roll(self: *Self, dir: Dir) void {
        var corner_opt: ?Pos = switch (dir) {
            .Up => Pos{ .x = 0, .y = 0 },
            .Right => Pos{ .x = self.width - 1, .y = 0 },
            .Down => Pos{ .x = self.width - 1, .y = self.height - 1 },
            .Left => Pos{ .x = 0, .y = self.height - 1 },
        };

        while (corner_opt) |start| : ({
            corner_opt = corner_opt.?.step(dir.flip(), self.width, self.height);
        }) {
            var current_opt: ?Pos = start;
            while (current_opt) |pos| : ({
                current_opt = current_opt.?.step(dir.rotateRight(), self.width, self.height);
            }) {
                if (self.get(pos.x, pos.y) == .Rock) {
                    self.set(pos.x, pos.y, .None);
                    const shifted = self.findShiftPos(dir, pos.x, pos.y);
                    self.set(shifted.x, shifted.y, .Rock);
                }
            }
        }
    }

    fn findShiftPos(self: Self, dir: Dir, x: usize, y: usize) Pos {
        var pos = Pos{ .x = x, .y = y };

        while (pos.step(dir, self.width, self.height)) |new_pos| {
            if (self.get(new_pos.x, new_pos.y) != .None) {
                return pos;
            }

            pos = new_pos;
        }

        return pos;
    }

    fn get(self: Self, x: usize, y: usize) Tile {
        return self.tiles[x + y * self.width];
    }

    fn set(self: *Self, x: usize, y: usize, tile: Tile) void {
        self.tiles[x + y * self.width] = tile;
    }

    fn weight(self: Self) usize {
        var total: usize = 0;

        for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (self.get(x, y) == .Rock) {
                    total += self.height - y;
                }
            }
        }

        return total;
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.tiles);
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try Grid.initParse(allocator, input);
    defer grid.deinit();

    grid.roll2(.Up);

    grid.print();

    return grid.weight();
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Cache = std.AutoHashMap(usize, usize);

    var cache = Cache.init(allocator);
    defer cache.deinit();

    var grid = try Grid.initParse(allocator, input);
    defer grid.deinit();

    const iterations = 1000000000;

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const hash = grid.hash();
        if (cache.get(hash)) |c| {
            const remaining_iterations = iterations - i;
            const cycle = i - c;

            const skip = remaining_iterations - @mod(remaining_iterations, cycle);

            std.debug.print("Found cycle of {}, current iteration {}, skipping {}\n", .{ cycle, i, skip });

            i += skip;
        } else {
            try cache.put(hash, i);
        }

        for ([_]Grid.Dir{ .Up, .Left, .Down, .Right }) |dir| {
            grid.roll2(dir);
        }

        if (@mod(i, 1000) == 0)
            std.debug.print("Iteration: {} ({:2}%)\n", .{ i, i * 100 / 1000000000 });
    }

    grid.print();
    return grid.weight();
}

pub fn main() !void {
    const content = comptime @embedFile("data/day14.txt");

    std.debug.print("~~ Day 14 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
