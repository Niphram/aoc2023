const std = @import("std");
const assert = std.debug.assert;

pub const sets = @import("./util/set.zig");

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

pub fn maxMultiplesOfAny(comptime T: type, buffer: []const T, needles: []const T) usize {
    var max_multiples: usize = 0;

    for (needles) |needle| {
        const count = std.mem.count(T, buffer, &[_]u8{needle});
        max_multiples = @max(count, max_multiples);
    }

    return max_multiples;
}

pub fn countUniquesOfAny(comptime T: type, buffer: []const T, needles: []const T) usize {
    var uniques: usize = 0;

    for (needles) |item| {
        if (std.mem.indexOfScalar(T, buffer, item) != null) {
            uniques += 1;
        }
    }

    return uniques;
}

pub fn countOfAny(comptime T: type, buffer: []const T, needles: []const T) usize {
    var count: usize = 0;

    for (needles) |needle| {
        count += std.mem.count(T, buffer, &[_]T{needle});
    }

    return count;
}

// Assumes both arrays are actual sets and b is a subset of a
pub fn removeSet(comptime T: type, comptime set: []const T, comptime remove: []const T) [set.len - remove.len]T {
    var new_set: [set.len - remove.len]T = undefined;
    var idx: usize = 0;
    for (set) |value| {
        if (std.mem.indexOfScalar(T, remove, value) == null) {
            new_set[idx] = value;
            idx += 1;
        }
    }

    return new_set;
}

pub fn greatestCommonDivisor(a: anytype, b: anytype) @TypeOf(a, b) {
    const T = @TypeOf(a, b);
    comptime assert(@typeInfo(T) == .Int);

    var a_n = a;
    var b_n = b;

    while (b_n != 0) {
        const tmp = b_n;
        b_n = @mod(a_n, b_n);
        a_n = tmp;
    }

    return a_n;
}

pub fn leastCommonMultiple(a: anytype, b: anytype) @TypeOf(a, b) {
    const T = @TypeOf(a, b);
    comptime assert(@typeInfo(T) == .Int);

    return a * b / greatestCommonDivisor(a, b);
}
