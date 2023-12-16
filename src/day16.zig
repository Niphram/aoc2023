const std = @import("std");
const util = @import("./util.zig");

const Grid = struct {
    const Self = @This();

    const Tile = struct {
        visited: std.EnumArray(Dir, bool) = std.EnumArray(Dir, bool).initFill(false),

        type: enum {
            Free,
            SplitterVertical,
            SplitterHorizontal,
            Mirror1,
            Mirror2,
        } = .Free,

        fn energized(self: @This()) bool {
            inline for (self.visited.values) |v| {
                if (v) return true;
            }

            return false;
        }
    };

    const Dir = enum {
        Up,
        Right,
        Down,
        Left,

        fn horizontal(self: @This()) bool {
            return self == .Left or self == .Right;
        }

        fn vertical(self: @This()) bool {
            return self == .Up or self == .Down;
        }
    };

    const Laser = struct {
        dir: Dir,

        x: usize,
        y: usize,

        fn rotateLeft(self: @This()) @This() {
            var copy = self;
            copy.dir = switch (self.dir) {
                .Up => .Left,
                .Right => .Up,
                .Down => .Right,
                .Left => .Down,
            };
            return copy;
        }

        fn rotateRight(self: @This()) @This() {
            var copy = self;
            copy.dir = switch (self.dir) {
                .Up => .Right,
                .Right => .Down,
                .Down => .Left,
                .Left => .Up,
            };
            return copy;
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
                const tile = self.tiles[self.index(x, y)];
                const char: u8 = if (tile.energized()) '#' else '.';

                std.debug.print("{c}", .{char});
            }
            std.debug.print("\n", .{});
        }
    }

    fn initParse(allocator: std.mem.Allocator, input: []const u8) !Self {
        const width = std.mem.indexOfScalar(u8, input, '\n') orelse input.len;
        const height = (input.len + 1) / (width + 1);

        const tiles = try allocator.alloc(Tile, width * height);
        @memset(tiles, Tile{});

        var i: usize = 0;
        var line_iter = std.mem.splitScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            for (line) |c| {
                tiles[i].type = switch (c) {
                    '.' => .Free,
                    '|' => .SplitterVertical,
                    '-' => .SplitterHorizontal,
                    '\\' => .Mirror1,
                    '/' => .Mirror2,
                    else => unreachable,
                };
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

    fn simulateLaser(self: *Self, laser: Laser) void {
        const tile = &self.tiles[self.index(laser.x, laser.y)];

        if (tile.visited.get(laser.dir)) {
            return;
        } else {
            tile.visited.set(laser.dir, true);
        }

        switch (tile.type) {
            .SplitterVertical, .SplitterHorizontal => {
                if ((laser.dir.horizontal() and tile.type == .SplitterVertical) or (laser.dir.vertical() and tile.type == .SplitterHorizontal)) {
                    if (self.stepLaser(laser.rotateLeft())) |l|
                        self.simulateLaser(l);
                    if (self.stepLaser(laser.rotateRight())) |l|
                        self.simulateLaser(l);
                } else {
                    if (self.stepLaser(laser)) |l| self.simulateLaser(l);
                }
            },
            .Mirror1 => { // "\"
                switch (laser.dir) {
                    .Up, .Down => {
                        if (self.stepLaser(laser.rotateLeft())) |l|
                            self.simulateLaser(l);
                    },
                    .Right, .Left => {
                        if (self.stepLaser(laser.rotateRight())) |l|
                            self.simulateLaser(l);
                    },
                }
            },
            .Mirror2 => { // "/"
                switch (laser.dir) {
                    .Up, .Down => {
                        if (self.stepLaser(laser.rotateRight())) |l|
                            self.simulateLaser(l);
                    },
                    .Right, .Left => {
                        if (self.stepLaser(laser.rotateLeft())) |l|
                            self.simulateLaser(l);
                    },
                }
            },
            else => {
                if (self.stepLaser(laser)) |l| self.simulateLaser(l);
            },
        }
    }

    fn stepLaser(self: Self, laser: Laser) ?Laser {
        var new_laser = laser;

        switch (laser.dir) {
            .Up => if (laser.y > 0) {
                new_laser.y -= 1;
            },
            .Down => if (laser.y < self.height - 1) {
                new_laser.y += 1;
            },
            .Left => if (laser.x > 0) {
                new_laser.x -= 1;
            },
            .Right => if (laser.x < self.width - 1) {
                new_laser.x += 1;
            },
        }

        return new_laser;
    }

    fn resetEnergized(self: *Self) void {
        for (self.tiles) |*tile| {
            tile.visited.set(.Up, false);
            tile.visited.set(.Right, false);
            tile.visited.set(.Down, false);
            tile.visited.set(.Left, false);
        }
    }

    fn tryAllEntrypoints(self: *Self) usize {
        var max: usize = 0;

        for (0..self.width) |x| {
            self.simulateLaser(Laser{ .x = x, .y = 0, .dir = .Down });
            max = @max(max, self.count());
            self.resetEnergized();

            self.simulateLaser(Laser{ .x = x, .y = self.height - 1, .dir = .Up });
            max = @max(max, self.count());
            self.resetEnergized();
        }

        for (0..self.height) |y| {
            self.simulateLaser(Laser{ .x = 0, .y = y, .dir = .Right });
            max = @max(max, self.count());
            self.resetEnergized();

            self.simulateLaser(Laser{ .x = self.width - 1, .y = y, .dir = .Left });
            max = @max(max, self.count());
            self.resetEnergized();
        }

        return max;
    }

    fn index(self: Self, x: usize, y: usize) usize {
        return x + y * self.width;
    }

    fn count(self: Self) usize {
        var total: usize = 0;

        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const tile = self.tiles[self.index(x, y)];
                if (tile.energized()) {
                    total += 1;
                }
            }
        }

        return total;
    }

    fn deinit(self: Self) void {
        self.allocator.free(self.tiles);
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try Grid.initParse(allocator, input);
    defer grid.deinit();
    grid.simulateLaser(Grid.Laser{ .x = 0, .y = 0, .dir = .Right });

    grid.print();

    return grid.count();
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try Grid.initParse(allocator, input);
    defer grid.deinit();
    return grid.tryAllEntrypoints();
}

pub fn main() !void {
    const content = comptime @embedFile("data/day16.txt");

    std.debug.print("~~ Day 16 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
