const std = @import("std");
const util = @import("./util.zig");

const Polygon = util.Polygon;
const Dir = util.Dir;
const Pos = util.Pos(isize);

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var polygon = Polygon.init(allocator);
    defer polygon.deinit();

    var current_pos = Pos{ .x = 0, .y = 0 };

    // Parse input
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const direction, const rest = util.splitScalarOnce(u8, line, ' ');
        const length = try std.fmt.parseInt(isize, util.splitScalarOnce(u8, rest, ' ')[0], 10);

        current_pos = current_pos.move(switch (direction[0]) {
            'R' => .R,
            'D' => .D,
            'L' => .L,
            'U' => .U,
            else => @panic("Unknown direction"),
        }, length);

        try polygon.addVertex(current_pos);
    }

    // Use Pick's theorem to calculate area
    return polygon.calculateArea() + (polygon.calculateManhattanPerimeter() / 2 + 1);
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var polygon = Polygon.init(allocator);
    defer polygon.deinit();

    var current_pos = Pos{ .x = 0, .y = 0 };

    // Parse input
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const instruction = util.splitScalarOnce(u8, line, '#')[1];

        const distance = try std.fmt.parseInt(isize, instruction[0..5], 16);
        const dir: Dir = @enumFromInt(instruction[5] - '0');

        current_pos = current_pos.move(dir, distance);
        try polygon.addVertex(current_pos);
    }

    // Use Pick's theorem to calculate area
    return polygon.calculateArea() + (polygon.calculateManhattanPerimeter() / 2 + 1);
}

pub fn main() !void {
    const content = comptime @embedFile("data/day18.txt");

    std.debug.print("~~ Day 18 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
