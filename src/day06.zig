const std = @import("std");
const util = @import("./util.zig");

const Race = struct {
    const Self = @This();

    time: usize,
    distance: usize,

    // Calculate the number of possible hold times
    fn marginOfError(self: Self) usize {
        const time: f64 = @floatFromInt(self.time);
        const dis: f64 = @floatFromInt(self.distance);

        // Derived from 'dis = hold_time * (time - hold_time)'
        const common: f64 = @sqrt(time * time - 4 * dis);
        const min: usize = @as(usize, @intFromFloat(0.5 * (time - common)));
        const max: usize = @as(usize, @intFromFloat(0.5 * (time + common)));

        return max - min;
    }
};

fn part1(input: []const u8) !usize {
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    // Get input lines
    const time_line = line_iter.next().?;
    const dis_line = line_iter.next().?;

    var time_iter = std.mem.tokenizeScalar(u8, util.splitScalarOnce(u8, time_line, ':')[1], ' ');
    var dis_iter = std.mem.tokenizeScalar(u8, util.splitScalarOnce(u8, dis_line, ':')[1], ' ');

    var total_margin_of_error: usize = 1;

    // Iterate through both lines at once
    while (time_iter.next()) |time_s| {
        const dis_s = dis_iter.next().?;

        // Parse time and distance
        const time = try std.fmt.parseInt(usize, time_s, 10);
        const dis = try std.fmt.parseInt(usize, dis_s, 10);

        // Calculate margin of error
        const race = Race{ .time = time, .distance = dis };
        total_margin_of_error *= race.marginOfError();
    }

    return total_margin_of_error;
}

// Read buffer and build number from all digits.
// Ignores any non-digits
fn readAllDigits(input: []const u8) usize {
    var number: usize = 0;

    for (input) |c| {
        if (std.ascii.isDigit(c)) {
            number = number * 10 + (c - '0');
        }
    }

    return number;
}

fn part2(input: []const u8) !usize {
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    const time_line = line_iter.next().?;
    const dis_line = line_iter.next().?;

    const time = readAllDigits(util.splitScalarOnce(u8, time_line, ':')[1]);
    const dis = readAllDigits(util.splitScalarOnce(u8, dis_line, ':')[1]);

    const race = Race{ .time = time, .distance = dis };
    return race.marginOfError();
}

pub fn main() !void {
    const content = comptime @embedFile("data/day06.txt");

    std.debug.print("~~ Day 06 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
