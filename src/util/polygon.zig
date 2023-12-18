const std = @import("std");

const Pos = @import("./geometry.zig").Pos(isize);

pub const SimplePolygon = struct {
    const Self = @This();

    vertices: std.ArrayList(Pos),

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .vertices = std.ArrayList(Pos).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        self.vertices.deinit();
    }

    pub fn addVertex(self: *Self, pos: Pos) !void {
        try self.vertices.append(pos);
    }

    // Calculates the area using the shoelace formula
    pub fn calculateArea(self: Self) usize {
        var signed_area: isize = 0;

        for (0..self.vertices.items.len) |i| {
            const a = self.vertices.items[i];
            const b = self.vertices.items[@mod(i + 1, self.vertices.items.len)];
            signed_area += a.x * b.y - b.x * a.y;
        }

        return @abs(signed_area) / 2;
    }

    // Calculates the perimeter using the manhattan distance
    pub fn calculateManhattanPerimeter(self: Self) usize {
        var perimeter: usize = 0;

        for (0..self.vertices.items.len) |i| {
            const a = self.vertices.items[i];
            const b = self.vertices.items[@mod(i + 1, self.vertices.items.len)];

            perimeter += a.manhattanDistance(b);
        }

        return perimeter;
    }
};
