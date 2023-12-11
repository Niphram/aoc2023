const std = @import("std");
const util = @import("./util.zig");

const Universe = struct {
    const Self = @This();

    const Galaxy = struct {
        x: usize,
        y: usize,

        fn manhattanDis(self: Self.Galaxy, other: Self.Galaxy) usize {
            const x_diff = @max(self.x, other.x) - @min(self.x, other.x);
            const y_diff = @max(self.y, other.y) - @min(self.y, other.y);

            return x_diff + y_diff;
        }
    };

    const Bounds = struct {
        x_min: usize,
        y_min: usize,
        x_max: usize,
        y_max: usize,
    };

    galaxies: std.ArrayList(Galaxy),

    fn init(allocator: std.mem.Allocator, input: []const u8) !Self {
        var galaxies = std.ArrayList(Galaxy).init(allocator);

        // Parse galaxies
        {
            var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');
            var y: usize = 0;
            while (lines_iter.next()) |line| : (y += 1) {
                for (line, 0..) |c, x| {
                    if (c == '#') {
                        try galaxies.append(.{ .x = x, .y = y });
                    }
                }
            }
        }

        return .{ .galaxies = galaxies };
    }

    fn expand(self: *Self, expansion_factor: usize) void {
        const bounds = self.getBounds();

        // Expand empty rows
        var row = bounds.y_max;
        while (row > bounds.y_min) : (row -= 1) {
            for (self.galaxies.items) |galaxy| {
                if (galaxy.y == row) break;
            } else {
                for (self.galaxies.items) |*galaxy| {
                    if (galaxy.y > row) galaxy.*.y += expansion_factor - 1;
                }
            }
        }

        // Expand empty columns
        var col = bounds.x_max;
        while (col > bounds.x_min) : (col -= 1) {
            for (self.galaxies.items) |galaxy| {
                if (galaxy.x == col) break;
            } else {
                for (self.galaxies.items) |*galaxy| {
                    if (galaxy.x > col) galaxy.*.x += expansion_factor - 1;
                }
            }
        }
    }

    fn calculateDistances(self: Self) usize {
        var total_distance: usize = 0;

        for (self.galaxies.items, 1..) |point_a, i| {
            for (self.galaxies.items[i..]) |point_b| {
                total_distance += point_a.distanceTo(point_b);
            }
        }

        return total_distance;
    }

    fn countGalaxies(self: Self) usize {
        return self.galaxies.items.len;
    }

    fn getBounds(self: Self) Bounds {
        var x_min: usize = std.math.maxInt(usize);
        var y_min: usize = std.math.maxInt(usize);
        var x_max: usize = 0;
        var y_max: usize = 0;

        for (self.galaxies.items) |galaxy| {
            x_min = @min(x_min, galaxy.x);
            y_min = @min(y_min, galaxy.y);
            x_max = @max(x_max, galaxy.x);
            y_max = @max(y_max, galaxy.y);
        }

        return .{ .x_min = x_min, .y_min = y_min, .x_max = x_max, .y_max = y_max };
    }

    fn deinit(self: *Self) void {
        self.galaxies.deinit();
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var universe = try Universe.init(allocator, input);
    defer universe.deinit();

    universe.expand(2);

    return universe.calculateDistances();
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var universe = try Universe.init(allocator, input);
    defer universe.deinit();

    universe.expand(1000000);

    return universe.calculateDistances();
}

pub fn main() !void {
    const content = comptime @embedFile("data/day11.txt");

    std.debug.print("~~ Day 11 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
