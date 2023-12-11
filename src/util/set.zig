const std = @import("std");
const assert = std.debug.assert;

pub fn countDuplicates(comptime T: type, buffer: []const T) usize {
    var duplicates: usize = 0;

    for (buffer, 1..) |value, i| {
        if (std.mem.indexOfScalarPos(T, buffer, i, value) != null) {
            duplicates += 1;
        }
    }

    return duplicates;
}

pub fn onlyUniqueValues(comptime T: type, buffer: []const T) bool {
    if (buffer.len == 1) return true;

    return std.mem.allEqual(T, buffer[1..], buffer[0]);
}

pub fn StaticBitSet(comptime T: type, comptime set_array: []const T) type {
    comptime assert(onlyUniqueValues(T, set_array));

    return struct {
        const Self = @This();

        bitset: std.StaticBitSet(set_array.len),

        pub fn initEmpty() Self {
            return .{ .bitset = std.StaticBitSet(set_array.len).initEmpty() };
        }

        pub fn initFull() Self {
            return .{ .bitset = std.StaticBitSet(set_array.len).initFull() };
        }

        pub fn set(self: *Self, values: []const T) void {
            for (values) |value| {
                self.bitset.set(std.mem.indexOfScalar(T, set_array, value).?);
            }
        }

        pub fn unset(self: *Self, values: []const T) void {
            for (values) |value| {
                self.bitset.unset(std.mem.indexOfScalar(T, set_array, value).?);
            }
        }

        pub fn count(self: Self) usize {
            return self.bitset.count();
        }

        pub fn findFirstSet(self: Self) ?T {
            const idx = self.bitset.findFirstSet() orelse return null;
            return set_array[idx];
        }
    };
}
