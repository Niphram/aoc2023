const std = @import("std");
const util = @import("./util.zig");

const Grid = struct {
    const Self = @This();

    const Reflection = struct {
        row: ?usize,
        col: ?usize,

        fn score(self: Reflection) usize {
            if (self.row) |row| {
                return (row + 1) * 100;
            } else if (self.col) |col| {
                return (col + 1);
            }

            unreachable;
        }
    };

    width: usize,
    height: usize,
    tiles: []u8,

    allocator: std.mem.Allocator,

    fn initParse(allocator: std.mem.Allocator, input: []const u8) !Self {
        const width = std.mem.indexOfScalar(u8, input, '\n') orelse input.len;
        const height = (input.len + 1) / (width + 1);

        const tiles = try allocator.alloc(u8, input.len);
        @memcpy(tiles, input);

        return .{
            .width = width,
            .height = height,
            .tiles = tiles,
            .allocator = allocator,
        };
    }

    fn findMirrorLine(self: Self, ignore_col: ?usize, ignore_row: ?usize) !?Reflection {
        var possible_vertical_line: ?usize = null;
        var possible_horizontal_line: ?usize = null;

        // Vertical Line
        {
            var possibilities = try std.DynamicBitSet.initFull(self.allocator, self.width - 1);
            defer possibilities.deinit();

            if (ignore_col) |i| {
                possibilities.unset(i);
            }

            for (0..self.height) |row| {
                mirror_loop: for (0..self.width - 1) |mirror_pos| {
                    if (!possibilities.isSet(mirror_pos)) continue :mirror_loop;

                    const max = @min(mirror_pos + 1, self.width - mirror_pos - 1);

                    for (0..max) |i| {
                        if (self.get(mirror_pos - i, row) != self.get(mirror_pos + i + 1, row)) {
                            possibilities.unset(mirror_pos);
                            continue :mirror_loop;
                        }
                    }
                }
            }

            if (possibilities.count() > 1) {
                return null;
            }

            possible_vertical_line = possibilities.findFirstSet();
        }

        // Horizontal Line
        {
            var possibilities = try std.DynamicBitSet.initFull(self.allocator, self.height - 1);
            defer possibilities.deinit();

            if (ignore_row) |i| {
                possibilities.unset(i);
            }

            for (0..self.width) |col| {
                mirror_loop: for (0..self.height - 1) |mirror_pos| {
                    if (!possibilities.isSet(mirror_pos)) continue :mirror_loop;

                    const max = @min(mirror_pos + 1, self.height - mirror_pos - 1);

                    for (0..max) |i| {
                        if (self.get(col, mirror_pos - i) != self.get(col, mirror_pos + i + 1)) {
                            possibilities.unset(mirror_pos);
                            continue :mirror_loop;
                        }
                    }
                }
            }

            if (possibilities.count() > 1) {
                return null;
            }

            possible_horizontal_line = possibilities.findFirstSet();
        }

        if (possible_vertical_line != null and possible_horizontal_line != null) return null;
        if (possible_vertical_line == null and possible_horizontal_line == null) return null;

        return .{ .col = possible_vertical_line, .row = possible_horizontal_line };
    }

    fn idx(self: Self, x: usize, y: usize) usize {
        return x + (y * (self.width + 1));
    }

    fn get(self: Self, x: usize, y: usize) u8 {
        return self.tiles[x + (y * (self.width + 1))];
    }
    fn summarize(self: Self, ignore: ?Reflection) !?Reflection {
        const col_ignore = if (ignore != null) ignore.?.col else null;
        const row_ignore = if (ignore != null) ignore.?.row else null;

        return self.findMirrorLine(col_ignore, row_ignore);
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.tiles);
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var total: usize = 0;

    var grid_iter = std.mem.tokenizeSequence(u8, input, "\n\n");

    var i: usize = 0;
    while (grid_iter.next()) |grid_s| : (i += 1) {
        var grid = try Grid.initParse(allocator, grid_s);
        defer grid.deinit();
        std.debug.print("Grid: {}, {}x{}\n", .{ i, grid.width, grid.height });
        const reflection = try grid.summarize(null);
        if (reflection) |r| {
            total += r.score();
        }
    }

    return total;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var total: usize = 0;

    var grid_iter = std.mem.tokenizeSequence(u8, input, "\n\n");

    var i: usize = 0;
    grids: while (grid_iter.next()) |grid_s| : (i += 1) {
        var grid = try Grid.initParse(allocator, grid_s);
        defer grid.deinit();

        const original_reflection = try grid.summarize(null);
        std.debug.print("Grid: {}, {}x{}, Reflection {?}\n", .{ i, grid.width, grid.height, original_reflection });

        for (0..grid.width) |x| {
            for (0..grid.height) |y| {
                const idx = grid.idx(x, y);

                grid.tiles[idx] = switch (grid.tiles[idx]) {
                    '.' => '#',
                    '#' => '.',
                    else => unreachable,
                };

                const reflection = try grid.summarize(original_reflection);

                grid.tiles[idx] = switch (grid.tiles[idx]) {
                    '.' => '#',
                    '#' => '.',
                    else => unreachable,
                };

                if (reflection) |r| {
                    total += r.score();
                    continue :grids;
                }
            }
        }
    }

    return total;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day13.txt");

    std.debug.print("~~ Day 13 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
