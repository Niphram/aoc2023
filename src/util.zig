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

pub fn splitSequenceOnce(comptime T: type, buffer: []const T, delimiter: []const T) std.meta.Tuple(&[_]type{ []const T, []const T }) {
    const delimiter_pos = std.mem.indexOf(u8, buffer, delimiter).?;
    const left = buffer[0..delimiter_pos];
    const right = buffer[delimiter_pos + delimiter.len ..];

    return .{ left, right };
}

pub fn splitScalarOnce(comptime T: type, buffer: []const T, delimiter: T) std.meta.Tuple(&[_]type{ []const T, []const T }) {
    const delimiter_pos = std.mem.indexOfScalar(u8, buffer, delimiter).?;
    const left = buffer[0..delimiter_pos];
    const right = buffer[delimiter_pos + 1 ..];

    return .{ left, right };
}
