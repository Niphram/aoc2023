const std = @import("std");
const util = @import("./util.zig");

const Dir = enum {
    R,
    D,
    L,
    U,

    fn parse(input: u8) @This() {
        return switch (input) {
            'R' => .R,
            'D' => .D,
            'L' => .L,
            'U' => .U,
            else => @panic("Unknown direction!"),
        };
    }
};

const Pos = struct {
    const Self = @This();

    x: isize,
    y: isize,

    fn step(self: Self, dir: Dir, distance: isize) Self {
        return switch (dir) {
            .U => .{ .x = self.x, .y = self.y - distance },
            .R => .{ .x = self.x + distance, .y = self.y },
            .D => .{ .x = self.x, .y = self.y + distance },
            .L => .{ .x = self.x - distance, .y = self.y },
        };
    }
};

const SimplePolygon = struct {
    const Self = @This();

    vertices: std.ArrayList(Pos),

    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .vertices = std.ArrayList(Pos).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: Self) void {
        self.vertices.deinit();
    }

    fn addVertex(self: *Self, pos: Pos) !void {
        try self.vertices.append(pos);
    }

    // Calculates the area using the shoelace formula
    fn calculateArea(self: Self) usize {
        var signed_area: isize = 0;

        for (0..self.vertices.items.len) |i| {
            const a = self.vertices.items[i];
            const b = self.vertices.items[@mod(i + 1, self.vertices.items.len)];
            signed_area += a.x * b.y - b.x * a.y;
        }

        return @abs(signed_area) / 2;
    }

    // Calculates the perimeter using the manhattan distance
    fn calculateManhattanPerimeter(self: Self) usize {
        var perimeter: usize = 0;

        for (0..self.vertices.items.len) |i| {
            const a = self.vertices.items[i];
            const b = self.vertices.items[@mod(i + 1, self.vertices.items.len)];
            perimeter += @abs(a.x - b.x) + @abs(a.y - b.y);
        }

        return perimeter;
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var polygon = SimplePolygon.init(allocator);
    defer polygon.deinit();

    var current_pos = Pos{ .x = 0, .y = 0 };

    // Parse input
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const direction, const rest = util.splitScalarOnce(u8, line, ' ');
        const length = try std.fmt.parseInt(isize, util.splitScalarOnce(u8, rest, ' ')[0], 10);

        current_pos = current_pos.step(Dir.parse(direction[0]), length);
        try polygon.addVertex(current_pos);
    }

    // Use Pick's theorem to calculate area
    return polygon.calculateArea() + (polygon.calculateManhattanPerimeter() / 2 + 1);
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var polygon = SimplePolygon.init(allocator);
    defer polygon.deinit();

    var current_pos = Pos{ .x = 0, .y = 0 };

    // Parse input
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const instruction = util.splitScalarOnce(u8, line, '#')[1];

        const distance = try std.fmt.parseInt(isize, instruction[0..5], 16);
        const dir: Dir = @enumFromInt(instruction[5] - '0');

        current_pos = current_pos.step(dir, distance);
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
