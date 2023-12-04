const std = @import("std");

pub fn findFirstOf(comptime T: type, slice: []const T, values: []const []const T) ?usize {
    for (0..slice.len) |i| {
        for (values, 0..) |value, n| {
            if (std.mem.startsWith(T, slice[i..], value)) {
                return n;
            }
        }
    }

    return null;
}

pub fn findLastOf(comptime T: type, slice: []const T, values: []const []const T) ?usize {
    for (0..slice.len) |i| {
        const part = slice[slice.len - i - 1 ..];

        for (values, 0..) |value, n| {
            if (std.mem.startsWith(T, part, value)) {
                return n;
            }
        }
    }

    return null;
}
