const std = @import("std");
const util = @import("./util.zig");

const Grid = struct {
    const Self = @This();

    const Mirror = union(enum) {
        col: usize,
        row: usize,

        none,

        fn score(self: Mirror) usize {
            return switch (self) {
                .col => |col| col + 1,
                .row => |row| (row + 1) * 100,
                .none => 0,
            };
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

    fn findVerticalMirror(self: Self, ignore_mirror: ?usize) !?usize {
        var possibilities = try std.DynamicBitSet.initFull(self.allocator, self.width - 1);
        defer possibilities.deinit();

        // Remove the ignored mirror from the possibilities
        if (ignore_mirror) |mirror| {
            possibilities.unset(mirror);
        }

        // For every row
        for (0..self.height) |row| {

            // Check remaining possibilities
            var remaining = possibilities.iterator(.{});
            mirror_loop: while (remaining.next()) |mirror_pos| {

                // Compare items left and right to check for reflection
                const end = @min(mirror_pos + 1, self.width - mirror_pos - 1);
                for (0..end) |i| {
                    if (self.get(mirror_pos - i, row) != self.get(mirror_pos + i + 1, row)) {
                        possibilities.unset(mirror_pos);
                        continue :mirror_loop;
                    }
                }
            }
        }

        return possibilities.findFirstSet();
    }

    fn findHorizontalMirror(self: Self, ignore_mirror: ?usize) !?usize {
        var possibilities = try std.DynamicBitSet.initFull(self.allocator, self.height - 1);
        defer possibilities.deinit();

        // Remove the ignored mirror from the possibilities
        if (ignore_mirror) |mirror| {
            possibilities.unset(mirror);
        }

        // For every column
        for (0..self.width) |col| {

            // Check remaining possibilities
            var remaining = possibilities.iterator(.{});
            mirror_loop: while (remaining.next()) |mirror_pos| {

                // Compare items above and below to check for reflection
                const end = @min(mirror_pos + 1, self.height - mirror_pos - 1);
                for (0..end) |i| {
                    if (self.get(col, mirror_pos - i) != self.get(col, mirror_pos + i + 1)) {
                        possibilities.unset(mirror_pos);
                        continue :mirror_loop;
                    }
                }
            }
        }

        return possibilities.findFirstSet();
    }

    fn findMirrorLine(self: Self, ignore_mirror: Mirror) !Mirror {
        const ignore_col = if (ignore_mirror == .col) ignore_mirror.col else null;
        const ignore_row = if (ignore_mirror == .row) ignore_mirror.row else null;

        if (try self.findVerticalMirror(ignore_col)) |col| {
            return Mirror{ .col = col };
        } else if (try self.findHorizontalMirror(ignore_row)) |row| {
            return Mirror{ .row = row };
        } else {
            return .none;
        }
    }

    fn idx(self: Self, x: usize, y: usize) usize {
        return x + (y * (self.width + 1));
    }

    fn get(self: Self, x: usize, y: usize) u8 {
        return self.tiles[self.idx(x, y)];
    }

    fn toggle(self: *Self, x: usize, y: usize) void {
        self.tiles[self.idx(x, y)] = switch (self.tiles[self.idx(x, y)]) {
            '.' => '#',
            '#' => '.',
            else => unreachable,
        };
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
    while (grid_iter.next()) |grid_s| {
        var grid = try Grid.initParse(allocator, grid_s);
        defer grid.deinit();

        const mirror = try grid.findMirrorLine(.none);
        total += mirror.score();
    }

    return total;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var total: usize = 0;

    var grid_iter = std.mem.tokenizeSequence(u8, input, "\n\n");
    grids: while (grid_iter.next()) |grid_s| {
        var grid = try Grid.initParse(allocator, grid_s);
        defer grid.deinit();

        const original_reflection = try grid.findMirrorLine(.none);

        // Flip every tile and check if a new mirror appears
        for (0..grid.width) |x| {
            for (0..grid.height) |y| {
                grid.toggle(x, y);
                const mirror = try grid.findMirrorLine(original_reflection);
                grid.toggle(x, y);

                if (mirror != .none) {
                    total += mirror.score();
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
