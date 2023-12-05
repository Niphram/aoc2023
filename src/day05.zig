const std = @import("std");
const util = @import("./util.zig");

const Range = struct {
    const Self = @This();

    source_start: usize,
    dest_start: usize,
    len: usize,

    fn map(self: Self, val: usize) ?usize {
        if (val >= self.source_start and val < (self.source_start + self.len)) {
            return val + self.dest_start - self.source_start;
        }

        return null;
    }

    fn parse(input: []const u8) !Self {
        var iter = std.mem.splitScalar(u8, input, ' ');
        const dest_start = try std.fmt.parseInt(usize, iter.next().?, 10);
        const source_start = try std.fmt.parseInt(usize, iter.next().?, 10);
        const len = try std.fmt.parseInt(usize, iter.next().?, 10);

        return Self{ .source_start = source_start, .dest_start = dest_start, .len = len };
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const seeds_s, const maps_s = util.splitSequenceOnce(u8, input, "\n\n");

    var data = std.ArrayList(usize).init(allocator);
    defer data.deinit();

    var seed_iter = std.mem.splitScalar(u8, util.splitScalarOnce(u8, seeds_s, ' ')[1], ' ');
    while (seed_iter.next()) |seed_s| {
        const seed = try std.fmt.parseInt(usize, seed_s, 10);
        try data.append(seed);
    }

    for (data.items) |*d| {
        var iter = std.mem.tokenizeSequence(u8, maps_s, "\n\n");

        while (iter.next()) |map_s| {
            var map_iter = std.mem.tokenizeScalar(u8, map_s, '\n');
            _ = map_iter.next();

            while (map_iter.next()) |map| {
                const range = try Range.parse(map);
                if (range.map(d.*)) |new_val| {
                    d.* = new_val;
                    break;
                }
            }
        }
    }

    return std.mem.min(usize, data.items);
}

const Range2 = struct {
    const Self = @This();

    start: isize,
    len: isize,

    // End Exclusive
    fn end(self: Self) isize {
        return self.start + self.len;
    }

    fn split(self: Self, val: isize) std.meta.Tuple(&[_]type{ Self, Self }) {
        const left = Self{ .start = self.start, .len = val - self.start };
        const right = Self{ .start = val, .len = self.len - left.len };

        return .{ left, right };
    }

    fn intersect(self: Self, other: Self) bool {
        if (self.start >= other.start and self.start < other.start + other.len) {
            return true;
        } else if (other.start >= self.start and other.start < self.start + self.len) {
            return true;
        }

        return false;
    }
};

const RangeMapper = struct {
    const Self = @This();

    range: Range2,
    offset: isize,

    fn parse(input: []const u8) !RangeMapper {
        var iter = std.mem.splitScalar(u8, input, ' ');
        const dest_start = try std.fmt.parseInt(isize, iter.next().?, 10);
        const start = try std.fmt.parseInt(isize, iter.next().?, 10);
        const len = try std.fmt.parseInt(isize, iter.next().?, 10);
        const offset: isize = dest_start - start;

        return Self{
            .range = Range2{ .start = start, .len = len },
            .offset = offset,
        };
    }
};

fn part2(input: []const u8) !isize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const seeds_s, const maps_s = util.splitSequenceOnce(u8, input, "\n\n");

    var ranges = std.ArrayList(Range2).init(allocator);
    defer ranges.deinit();

    var seed_iter = std.mem.splitScalar(u8, util.splitScalarOnce(u8, seeds_s, ' ')[1], ' ');
    while (seed_iter.next()) |seed_s| {
        const start = try std.fmt.parseInt(isize, seed_s, 10);
        const len = try std.fmt.parseInt(isize, seed_iter.next().?, 10);

        try ranges.append(Range2{ .start = start, .len = len });
    }

    var minimum: isize = std.math.maxInt(isize);

    // Map
    var iter = std.mem.tokenizeSequence(u8, maps_s, "\n\n");
    while (iter.next()) |map_s| {
        const map_title, const map_data = util.splitScalarOnce(u8, map_s, '\n');

        std.debug.print("{s}\n", .{map_title});

        var new_ranges = std.ArrayList(Range2).init(allocator);
        defer new_ranges.deinit();

        var map_iter = std.mem.tokenizeScalar(u8, map_data, '\n');
        while (map_iter.next()) |map| {
            const mapper = try RangeMapper.parse(map);

            std.debug.print("Mapper: {any}\n", .{mapper});

            // Ranges
            const len = ranges.items.len;
            for (0..len) |i| {
                _ = i;

                var range = ranges.orderedRemove(0);

                std.debug.print("Range begin: {any}\n", .{range});

                // Left
                if (range.start < mapper.range.start and range.end() > mapper.range.start) {
                    const left, const right = range.split(mapper.range.start);

                    std.debug.print("Left: {any}\n", .{left});

                    try ranges.append(left);
                    range = right;
                }

                // Right
                if (range.start < mapper.range.end() and range.end() > mapper.range.end()) {
                    const left, const right = range.split(mapper.range.end());

                    std.debug.print("Right: {any}\n", .{right});

                    try ranges.append(right);
                    range = left;
                }

                // Middle
                if (range.start >= mapper.range.start and range.end() <= mapper.range.end()) {
                    range.start += mapper.offset;

                    std.debug.print("Middle: {any}\n", .{range});

                    try new_ranges.append(range);
                } else {
                    std.debug.print("Range untouched\n", .{});
                    try ranges.append(range);
                }
            }

            std.debug.print("\n", .{});
        }

        try ranges.appendSlice(new_ranges.items);

        if (iter.peek() == null) {
            for (ranges.items) |range| {
                minimum = @min(minimum, range.start);
            }
        }
    }

    return minimum;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day05.txt");

    std.debug.print("~~ Day 05 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
