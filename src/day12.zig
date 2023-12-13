const std = @import("std");
const util = @import("./util.zig");

const Cache = std.AutoHashMap(u64, usize);

const Record = struct {
    springs: []const u8,
    connected: []const u8,

    fn hash(self: Record) u64 {
        var h = std.hash.Wyhash.init(0);
        h.update(self.springs);
        h.update(self.connected);
        return h.final();
    }

    fn countPossibleStates(self: *Record, cache: *Cache) !usize {
        if (cache.get(self.hash())) |res| {
            return res;
        }

        if (self.connected.len == 0) {
            if (std.mem.indexOfScalar(u8, self.springs, '#') != null) {
                return 0;
            } else {
                return 1;
            }
        }

        var possibilities: usize = 0;

        for (0..self.springs.len) |i| {
            const len = self.connected[0];

            if (self.contigiousDefect(i, len)) {
                const next = @min(i + len + 1, self.springs.len);
                const rest_springs = self.springs[next..];
                const rest_connected = self.connected[1..];

                var new_record = Record{
                    .springs = rest_springs,
                    .connected = rest_connected,
                };

                possibilities += try new_record.countPossibleStates(cache);
            }

            // If were on a guaranteed damaged spring, this has to be the start of the series
            if (self.springs[i] == '#') {
                break;
            }
        }

        try cache.put(self.hash(), possibilities);
        return possibilities;
    }

    fn contigiousDefect(self: Record, start: usize, len: usize) bool {
        const end = start + len;
        if (end > self.springs.len) return false;

        for (start..end) |i| {
            if (self.springs[i] == '.') {
                return false;
            }
        }

        if (end == self.springs.len) {
            return true;
        }

        return self.springs[end] != '#';
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = Cache.init(allocator);
    defer cache.deinit();

    var total: usize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var idx: usize = 1;
    while (line_iter.next()) |line| : (idx += 1) {
        const springs, const conditions_s = util.splitScalarOnce(u8, line, ' ');

        var defects = try allocator.alloc(u8, std.mem.count(u8, conditions_s, ",") + 1);
        defer allocator.free(defects);

        var i: usize = 0;
        var condition_iter = std.mem.tokenizeScalar(u8, conditions_s, ',');
        while (condition_iter.next()) |n| : (i += 1) {
            defects[i] = try std.fmt.parseUnsigned(u8, n, 10);
        }

        var record = Record{ .connected = defects, .springs = springs };
        const possibilities = try record.countPossibleStates(&cache);

        total += possibilities;
    }

    return total;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var total: usize = 0;

    var cache = Cache.init(allocator);
    defer cache.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var idx: usize = 1;
    while (line_iter.next()) |line| : (idx += 1) {
        const springs_s, const conditions_s = util.splitScalarOnce(u8, line, ' ');

        var springs = try allocator.alloc(u8, (springs_s.len + 1) * 5 - 1);
        defer allocator.free(springs);
        const group_count = std.mem.count(u8, conditions_s, ",") + 1;
        var defects = try allocator.alloc(u8, group_count * 5);
        defer allocator.free(defects);

        @memset(springs, '?');
        for (0..5) |copy| {
            const start = copy * (springs_s.len + 1);
            const end = start + springs_s.len;
            @memcpy(springs[start..end], springs_s);
        }

        {
            var i: usize = 0;
            var condition_iter = std.mem.tokenizeScalar(u8, conditions_s, ',');
            while (condition_iter.next()) |n| : (i += 1) {
                defects[i] = try std.fmt.parseUnsigned(u8, n, 10);
            }

            for (1..5) |copy| {
                const start = copy * group_count;
                const end = start + group_count;
                @memcpy(defects[start..end], defects[0..group_count]);
            }
        }

        std.debug.print("{any}\n", .{defects});

        var record = Record{ .connected = defects, .springs = springs };
        const possibilities = try record.countPossibleStates(&cache);

        std.debug.print("Record {:3}: {}\n", .{ idx, possibilities });

        // record.print();

        total += possibilities;
    }

    return total;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day12.txt");

    std.debug.print("~~ Day 12 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
