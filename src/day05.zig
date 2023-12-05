const std = @import("std");
const util = @import("./util.zig");

const Range = struct {
    const Self = @This();

    start: isize,
    len: isize,

    // End Exclusive
    fn end(self: Self) isize {
        return self.start + self.len;
    }

    // Splits the range into two parts (value will be contained in right half)
    fn split(self: Self, value: isize) std.meta.Tuple(&[_]type{ Self, Self }) {
        const left = Self{ .start = self.start, .len = value - self.start };
        const right = Self{ .start = value, .len = self.len - left.len };

        return .{ left, right };
    }

    // Returns true, if this range contains the value (inclusive)
    fn containsValue(self: Self, value: isize) bool {
        return value >= self.start and value < self.end();
    }

    // Returns true, if this range completely contains the other range (inclusive)
    fn containsRange(self: Self, other: Self) bool {
        return self.containsValue(other.start) and self.containsValue(other.end() - 1);
    }
};

const RangeMapper = struct {
    const Self = @This();

    range: Range,
    offset: isize,

    fn parse(input: []const u8) !RangeMapper {
        var iter = std.mem.splitScalar(u8, input, ' ');
        const dest = try std.fmt.parseInt(isize, iter.next().?, 10);
        const source = try std.fmt.parseInt(isize, iter.next().?, 10);
        const len = try std.fmt.parseInt(isize, iter.next().?, 10);
        const offset: isize = dest - source;

        return Self{
            .range = Range{ .start = source, .len = len },
            .offset = offset,
        };
    }

    // If the value is contained in the range, map it to it's new value
    // Otherwise return null
    fn map(self: Self, value: isize) ?isize {
        if (self.range.containsValue(value)) {
            return value + self.offset;
        }

        return null;
    }
};

fn part1(input: []const u8) !isize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Split input into seeds and category-maps
    const seed_line, const maps_input = util.splitSequenceOnce(u8, input, "\n\n");

    // List of locations to be mapped
    var locations = std.ArrayList(isize).init(allocator);
    defer locations.deinit();

    // Read seeds
    var seed_iter = std.mem.splitScalar(u8, util.splitScalarOnce(u8, seed_line, ' ')[1], ' ');
    while (seed_iter.next()) |seed| {
        try locations.append(try std.fmt.parseInt(isize, seed, 10));
    }

    // Iterate through each location
    for (locations.items) |*location| {
        var map_category_iter = std.mem.tokenizeSequence(u8, maps_input, "\n\n");

        // Iterate through all category maps
        while (map_category_iter.next()) |category| {
            var map_iter = std.mem.tokenizeScalar(u8, category, '\n');

            // Skip map header
            _ = map_iter.next();

            // Iterate through every map
            while (map_iter.next()) |map| {
                const mapper = try RangeMapper.parse(map);

                // If location is in the range, map it
                if (mapper.map(location.*)) |new_val| {
                    location.* = new_val;
                    break;
                }
            }
        }
    }

    // Return minimum
    return std.mem.min(isize, locations.items);
}

fn part2(input: []const u8) !isize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Split input into seeds and category-maps
    const seeds_s, const maps_s = util.splitSequenceOnce(u8, input, "\n\n");

    // Keeps track of all seed ranges
    var ranges = std.ArrayList(Range).init(allocator);
    defer ranges.deinit();

    // Read all seed ranges
    var seed_iter = std.mem.splitScalar(u8, util.splitScalarOnce(u8, seeds_s, ' ')[1], ' ');
    while (seed_iter.next()) |start_s| {
        const start = try std.fmt.parseInt(isize, start_s, 10);
        const len = try std.fmt.parseInt(isize, seed_iter.next().?, 10);

        try ranges.append(Range{ .start = start, .len = len });
    }

    // Map
    var iter = std.mem.tokenizeSequence(u8, maps_s, "\n\n");
    while (iter.next()) |map_s| {
        var map_iter = std.mem.tokenizeScalar(u8, map_s, '\n');

        // Skip category header
        _ = map_iter.next();

        // Keep track of already mapped ranges, skip those for the rest of the category
        var completed_ranges: usize = 0;

        while (map_iter.next()) |map| {
            const mapper = try RangeMapper.parse(map);

            // Iterate through all unmapped ranges
            // List Layout => [...completed_ranges][...ranges][...new_ranges]
            for (completed_ranges..ranges.items.len) |range_idx| {
                {
                    // Get range from list
                    const range = &ranges.items[range_idx];

                    // If range intersects the mapped range on the left side
                    if (range.*.start < mapper.range.start and mapper.range.start < range.*.end()) {
                        // Split the range
                        const left, range.* = range.*.split(mapper.range.start);
                        try ranges.append(left);
                    }
                }

                {
                    // Get range from list, may have changed because of reallocation
                    const range = &ranges.items[range_idx];

                    // If range intersects the mapped range on the right side
                    if (range.*.start < mapper.range.end() and mapper.range.end() < range.*.end()) {
                        // Split the range
                        range.*, const right = range.*.split(mapper.range.end());
                        try ranges.append(right);
                    }
                }

                {
                    // Get range from list, may have changed because of reallocation
                    const range = &ranges.items[range_idx];

                    // If the range is completely contained inside
                    if (mapper.range.containsRange(range.*)) {
                        // Offset the range
                        range.*.start += mapper.offset;
                        // Move range to the completed part of the list
                        std.mem.swap(Range, range, &ranges.items[completed_ranges]);
                        // Increment to skip this range for the current category
                        completed_ranges += 1;
                    }
                }
            }
        }
    }

    // Find lowest starting location
    var minimum: isize = std.math.maxInt(isize);

    for (ranges.items) |range| {
        minimum = @min(minimum, range.start);
    }

    return minimum;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day05.txt");

    std.debug.print("~~ Day 05 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
