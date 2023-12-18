const std = @import("std");

pub const Dir = enum { R, D, L, U };

pub fn Pos(comptime T: anytype) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn move(self: Self, dir: Dir, distance: T) Self {
            return switch (dir) {
                .U => .{ .x = self.x, .y = self.y - distance },
                .R => .{ .x = self.x + distance, .y = self.y },
                .D => .{ .x = self.x, .y = self.y + distance },
                .L => .{ .x = self.x - distance, .y = self.y },
            };
        }

        pub fn manhattanDistance(self: Self, other: Self) usize {
            const x_diff: usize = @intCast(if (self.x > other.x) self.x - other.x else other.x - self.x);
            const y_diff: usize = @intCast(if (self.y > other.y) self.y - other.y else other.y - self.y);

            return x_diff + y_diff;
        }
    };
}
