const std = @import("std");
const util = @import("./util.zig");

const Map = struct {
    const Node = struct {
        left: []const u8,
        right: []const u8,
    };

    const Self = @This();

    nodes: std.StringHashMap(Node),

    fn init(allocator: std.mem.Allocator) Self {
        return Self{ .nodes = std.StringHashMap(Node).init(allocator) };
    }

    fn iterator(self: *const Self) std.StringHashMap(Node).Iterator {
        return self.nodes.iterator();
    }

    fn insertNode(self: *Self, input: []const u8) !void {
        const name, const links = util.splitSequenceOnce(u8, input, " = ");
        const left, const right = util.splitSequenceOnce(u8, links, ", ");

        try self.nodes.put(name, .{ .left = left[1..], .right = right[0 .. right.len - 1] });
    }

    fn insertNodes(self: *Self, input: []const u8) !void {
        var nodes_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (nodes_iter.next()) |node| {
            try self.insertNode(node);
        }
    }

    fn move(self: Self, node_name: []const u8, instruction: u8) []const u8 {
        const node = self.nodes.get(node_name).?;

        return switch (instruction) {
            'L' => node.left,
            'R' => node.right,
            else => unreachable,
        };
    }

    fn countStepsTo(self: Self, start: []const u8, end_suffix: []const u8, instructions: []const u8) usize {
        var step: usize = 0;

        var current_node: []const u8 = start;
        while (true) : (step += 1) {
            const instruction = instructions[step % instructions.len];

            current_node = self.move(current_node, instruction);

            if (std.mem.endsWith(u8, current_node, end_suffix)) {
                break;
            }
        }

        return step + 1;
    }

    fn deinit(self: *Self) void {
        self.nodes.deinit();
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const instructions, const nodes_input = util.splitSequenceOnce(u8, input, "\n\n");

    var nodes = Map.init(allocator);
    defer nodes.deinit();

    try nodes.insertNodes(nodes_input);

    return nodes.countStepsTo("AAA", "ZZZ", instructions);
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const instructions, const nodes_input = util.splitSequenceOnce(u8, input, "\n\n");

    var nodes = Map.init(allocator);
    defer nodes.deinit();

    try nodes.insertNodes(nodes_input);

    var lcm: usize = 1;

    var nodes_iter = nodes.iterator();
    while (nodes_iter.next()) |node| {
        if (std.mem.endsWith(u8, node.key_ptr.*, "A")) {
            const steps = nodes.countStepsTo(node.key_ptr.*, "Z", instructions);

            lcm = util.leastCommonMultiple(lcm, steps);
        }
    }

    return lcm;
}

pub fn main() !void {
    const content = comptime @embedFile("data/day08.txt");

    std.debug.print("~~ Day 08 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
