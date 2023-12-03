const std = @import("std");

const SymbolPos = struct { type: u8, x: isize = 0, y: isize = 0 };

const NumberPos = struct {
    number: usize = 0,
    x: isize = 0,
    y: isize = 0,
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var numbers = std.ArrayList(NumberPos).init(allocator);
    defer numbers.deinit();

    var symbols = std.ArrayList(SymbolPos).init(allocator);
    defer symbols.deinit();

    // Find numbers
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    var curY: isize = 0;
    while (linesIter.next()) |line| : (curY += 1) {
        var items = std.mem.splitAny(u8, line, ".#@/*+$-=&%");
        var curX: isize = 0;
        while (items.next()) |pull| : (curX += 1) {
            if (pull.len != 0) {
                const number = try std.fmt.parseInt(usize, pull, 10);
                try numbers.append(NumberPos{ .number = number, .x = curX, .y = curY });
                curX += @intCast(pull.len);
            }
        }
    }

    // Find stars
    linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    curY = 0;
    while (linesIter.next()) |line| : (curY += 1) {
        for (line, 0..) |char, curX| {
            if (char != '.' and !std.ascii.isDigit(char)) {
                try symbols.append(SymbolPos{ .type = char, .x = @intCast(curX), .y = curY });
            }
        }
    }

    var sum: usize = 0;
    for (numbers.items) |number| {
        for (symbols.items) |symbol| {
            if (@abs(symbol.y - number.y) <= 1) {
                const numberLength: isize = @intCast(std.math.log10(number.number + 1));
                if (symbol.x >= (number.x - 1) and symbol.x <= (number.x + numberLength + 1)) {
                    sum += number.number;
                    break;
                }
            }
        }
    }

    return sum;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var numbers = std.ArrayList(NumberPos).init(allocator);
    defer numbers.deinit();

    var stars = std.ArrayList(SymbolPos).init(allocator);
    defer stars.deinit();

    // Find numbers
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    var curY: isize = 0;
    while (linesIter.next()) |line| : (curY += 1) {
        var items = std.mem.splitAny(u8, line, ".#@/*+$-=&%");
        var curX: isize = 0;
        while (items.next()) |pull| : (curX += 1) {
            if (pull.len != 0) {
                const number = try std.fmt.parseInt(usize, pull, 10);
                try numbers.append(NumberPos{ .number = number, .x = curX, .y = curY });
                curX += @intCast(pull.len);
            }
        }
    }

    // Find stars
    linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    curY = 0;
    while (linesIter.next()) |line| : (curY += 1) {
        for (line, 0..) |char, curX| {
            if (char == '*') {
                try stars.append(SymbolPos{ .type = char, .x = @intCast(curX), .y = curY });
            }
        }
    }

    var sum: usize = 0;
    for (stars.items) |star| {
        var adjacentNumbers = std.ArrayList(usize).init(allocator);
        defer adjacentNumbers.deinit();

        for (numbers.items) |number| {
            if (@abs(star.y - number.y) <= 1) {
                const numberLength: isize = @intCast(std.math.log10(number.number + 1));
                if (star.x >= (number.x - 1) and star.x <= (number.x + numberLength + 1)) {
                    try adjacentNumbers.append(number.number);
                }
            }
        }

        if (adjacentNumbers.items.len == 2) {
            sum += adjacentNumbers.items[0] * adjacentNumbers.items[1];
        }
    }

    return sum;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day03.txt");

    std.debug.print("~~ Day 03 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
