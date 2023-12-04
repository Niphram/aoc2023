const std = @import("std");

const Pos = struct {
    x: usize = 0,
    y: usize = 0,

    fn new(x: usize, y: usize) Pos {
        return Pos{ .x = x, .y = y };
    }
};

const NumberPos = struct {
    number: usize = 0,
    pos: Pos = Pos{},

    fn new(number: usize, x: usize, y: usize) NumberPos {
        return NumberPos{ .number = number, .pos = Pos.new(x, y) };
    }

    fn digits(self: *const NumberPos) usize {
        if (self.number == 0) return 1;
        return std.math.log10_int(self.number) + 1;
    }

    fn next_to(self: *const NumberPos, pos: Pos) bool {
        const xAdjacent = pos.x + 1 >= self.pos.x and pos.x <= self.pos.x + self.digits();
        const yAdjacent = pos.y + 1 >= self.pos.y and pos.y <= self.pos.y + 1;

        return xAdjacent and yAdjacent;
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var numbers = std.ArrayList(NumberPos).init(allocator);
    defer numbers.deinit();

    var symbols = std.ArrayList(Pos).init(allocator);
    defer symbols.deinit();

    // Find numbers
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    var y: usize = 0;
    while (linesIter.next()) |line| : (y += 1) {
        var partNumberIter = std.mem.splitAny(u8, line, ".#@/*+$-=&%");
        var x: usize = 0;
        while (partNumberIter.next()) |partNumber| : (x += 1) {
            if (partNumber.len != 0) {
                const number = try std.fmt.parseInt(usize, partNumber, 10);
                try numbers.append(NumberPos.new(number, x, y));
                x += partNumber.len;
            }
        }
    }

    // Find all symbols
    linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    y = 0;
    while (linesIter.next()) |line| : (y += 1) {
        for (line, 0..) |char, x| {
            if (char != '.' and !std.ascii.isDigit(char)) {
                try symbols.append(Pos.new(x, y));
            }
        }
    }

    var sum: usize = 0;
    // For every number
    for (numbers.items) |number| {
        for (symbols.items) |symbol| {
            // Check if there is a symbol next to it
            if (number.next_to(symbol)) {
                sum += number.number;
                break;
            }
        }
    }

    return sum;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var numbers = std.ArrayList(NumberPos).init(allocator);
    defer numbers.deinit();

    var stars = std.ArrayList(Pos).init(allocator);
    defer stars.deinit();

    // Find numbers
    var linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    var y: usize = 0;
    while (linesIter.next()) |line| : (y += 1) {
        var partNumberIter = std.mem.splitAny(u8, line, ".#@/*+$-=&%");
        var x: usize = 0;
        while (partNumberIter.next()) |partNumber| : (x += 1) {
            if (partNumber.len != 0) {
                const number = try std.fmt.parseInt(usize, partNumber, 10);
                try numbers.append(NumberPos.new(number, x, y));
                x += partNumber.len;
            }
        }
    }

    // Find stars
    linesIter = std.mem.tokenizeScalar(u8, input, '\n');
    y = 0;
    while (linesIter.next()) |line| : (y += 1) {
        for (line, 0..) |char, x| {
            if (char == '*') {
                try stars.append(Pos.new(x, y));
            }
        }
    }

    var sum: usize = 0;
    for (stars.items) |star| {
        var count: usize = 0;
        var product: usize = 1;

        for (numbers.items) |number| {
            if (number.next_to(star)) {
                count += 1;
                product *= number.number;
            }
        }

        if (count == 2) {
            sum += product;
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
