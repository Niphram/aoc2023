const std = @import("std");
const util = @import("./util.zig");

const Category = enum(u8) {
    CoolLooking = 'x',
    Musical = 'm',
    Aerodynamic = 'a',
    Shiny = 's',
};

const Part = std.EnumArray(Category, usize);

fn printPart(part: Part) void {
    std.debug.print("Part: X={} M={} A={} S={}\n", .{
        part.get(.CoolLooking),
        part.get(.Musical),
        part.get(.Aerodynamic),
        part.get(.Shiny),
    });
}

const WorkflowTarget = union(enum) {
    accepted,
    rejected,
    next_rule: []const u8,
};

const Rule = struct {
    check: union(enum) {
        none,
        lessThan: std.meta.Tuple(&[_]type{ Category, usize }),
        moreThan: std.meta.Tuple(&[_]type{ Category, usize }),
    },
    target: WorkflowTarget,

    fn parse(input: []const u8) !@This() {
        if (std.mem.indexOfScalar(u8, input, ':') == null) {
            return .{
                .check = .none,
                .target = switch (input[0]) {
                    'A' => .{ .accepted = {} },
                    'R' => .{ .rejected = {} },
                    else => .{ .next_rule = input },
                },
            };
        }

        const value_s, const target_s = util.splitScalarOnce(u8, input[2..], ':');

        const category: Category = @enumFromInt(input[0]);
        const value = try std.fmt.parseUnsigned(usize, value_s, 10);

        return .{
            .check = switch (input[1]) {
                '<' => .{ .lessThan = .{ category, value } },
                '>' => .{ .moreThan = .{ category, value } },
                else => @panic("Unknown comparison"),
            },
            .target = switch (target_s[0]) {
                'A' => .{ .accepted = {} },
                'R' => .{ .rejected = {} },
                else => .{ .next_rule = target_s },
            },
        };
    }

    fn apply(self: @This(), part: Part) bool {
        return switch (self.check) {
            .none => true,
            .lessThan => |check| part.get(check[0]) < check[1],
            .moreThan => |check| part.get(check[0]) > check[1],
        };
    }
};

fn printRule(rule: Rule) void {
    switch (rule.check) {
        .none => std.debug.print("Rule: Always => {any}\n", .{rule.target}),
        .lessThan => |op| std.debug.print("Rule: {c} < {} => {any}\n", .{ @intFromEnum(op[0]), op[1], rule.target }),
        .moreThan => |op| std.debug.print("Rule: {c} > {} => {any}\n", .{ @intFromEnum(op[0]), op[1], rule.target }),
    }
}

const Workflow = struct {
    rules: std.ArrayList(Rule),

    allocator: std.mem.Allocator,

    fn initParse(allocator: std.mem.Allocator, input: []const u8) !@This() {
        var rules = std.ArrayList(Rule).init(allocator);

        var rule_iter = std.mem.splitScalar(u8, input, ',');
        while (rule_iter.next()) |rule_s| {
            try rules.append(try Rule.parse(rule_s));
        }

        return .{
            .allocator = allocator,
            .rules = rules,
        };
    }

    fn deinit(self: @This()) void {
        self.rules.deinit();
    }

    fn apply(self: @This(), part: Part) WorkflowTarget {
        for (self.rules.items) |rule| {
            if (rule.apply(part)) return rule.target;
        }

        unreachable;
    }
};

fn part1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const workflows_s, const parts_s = util.splitSequenceOnce(u8, input, "\n\n");

    var workflows = std.StringHashMap(Workflow).init(allocator);

    defer {
        var workflow_iter = workflows.iterator();
        while (workflow_iter.next()) |entry| entry.value_ptr.deinit();
        workflows.deinit();
    }

    {
        var line_iter = std.mem.splitScalar(u8, workflows_s, '\n');
        while (line_iter.next()) |workflow_s| {
            const name, const workflow = util.splitScalarOnce(u8, workflow_s, '{');
            const parsed = try Workflow.initParse(allocator, workflow[0 .. workflow.len - 1]);
            try workflows.put(name, parsed);
        }
    }

    var total: usize = 0;

    {
        const starting_workflow = "in";
        var line_iter = std.mem.tokenizeScalar(u8, parts_s, '\n');
        while (line_iter.next()) |part_s| {
            const trimmed = std.mem.trim(u8, part_s, "{}");

            var part_iter = std.mem.splitScalar(u8, trimmed, ',');

            const part = Part.init(.{
                .CoolLooking = try std.fmt.parseUnsigned(usize, part_iter.next().?[2..], 10),
                .Musical = try std.fmt.parseUnsigned(usize, part_iter.next().?[2..], 10),
                .Aerodynamic = try std.fmt.parseUnsigned(usize, part_iter.next().?[2..], 10),
                .Shiny = try std.fmt.parseUnsigned(usize, part_iter.next().?[2..], 10),
            });

            var current_workflow: WorkflowTarget = .{ .next_rule = starting_workflow };
            while (current_workflow == .next_rule) {
                const workflow = workflows.get(current_workflow.next_rule).?;

                current_workflow = workflow.apply(part);
            }

            switch (current_workflow) {
                .accepted => {
                    total += part.get(.CoolLooking);
                    total += part.get(.Musical);
                    total += part.get(.Aerodynamic);
                    total += part.get(.Shiny);
                },
                else => {},
            }
        }
    }

    return total;
}

const Range = struct {
    min: usize = 1,
    max: usize = 4001,

    fn split(self: @This(), value: usize) [2]Range {
        var left = self;
        var right = self;

        left.max = @min(value + 1, left.max);
        right.min = @max(value + 1, right.min);

        return [_]Range{ left, right };
    }

    fn values(self: @This()) usize {
        return if (self.max > self.min)
            self.max - self.min
        else
            0;
    }
};

const InputRange = std.EnumArray(Category, Range);

fn analyzeWorkflows(current: WorkflowTarget, range: InputRange, workflows: *std.StringHashMap(Workflow)) usize {
    var current_range = range;

    switch (current) {
        .accepted => {
            var total: usize = 1;
            total *= current_range.get(.CoolLooking).values();
            total *= current_range.get(.Musical).values();
            total *= current_range.get(.Aerodynamic).values();
            total *= current_range.get(.Shiny).values();
            return total;
        },
        .rejected => return 0,
        .next_rule => {},
    }

    const workflow = workflows.get(current.next_rule).?;

    var total: usize = 0;

    for (workflow.rules.items) |rule| {
        total += switch (rule.check) {
            .none => analyzeWorkflows(rule.target, current_range, workflows),
            .lessThan => |check| blk: {
                const left_range, const right_range = current_range.get(check[0]).split(check[1] - 1);

                // Update new range
                var new_range = current_range;
                new_range.set(check[0], left_range);

                // Update current range
                current_range.set(check[0], right_range);

                break :blk analyzeWorkflows(rule.target, new_range, workflows);
            },
            .moreThan => |check| blk: {
                const left_range, const right_range = current_range.get(check[0]).split(check[1]);

                // Update new range
                var new_range = current_range;
                new_range.set(check[0], right_range);

                // Update current range
                current_range.set(check[0], left_range);

                break :blk analyzeWorkflows(rule.target, new_range, workflows);
            },
        };
    }

    return total;
}

fn part2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const workflows_s = util.splitSequenceOnce(u8, input, "\n\n")[0];

    var workflows = std.StringHashMap(Workflow).init(allocator);

    defer {
        var workflow_iter = workflows.iterator();
        while (workflow_iter.next()) |entry| entry.value_ptr.deinit();
        workflows.deinit();
    }

    {
        var line_iter = std.mem.splitScalar(u8, workflows_s, '\n');
        while (line_iter.next()) |workflow_s| {
            const name, const workflow = util.splitScalarOnce(u8, workflow_s, '{');
            const parsed = try Workflow.initParse(allocator, workflow[0 .. workflow.len - 1]);
            try workflows.put(name, parsed);
        }
    }

    return analyzeWorkflows(.{ .next_rule = "in" }, InputRange.initFill(.{}), &workflows);
}

pub fn main() !void {
    const content = comptime @embedFile("data/day19.txt");

    std.debug.print("~~ Day 19 ~~\n", .{});
    std.debug.print("Part 1: {}\n", .{try part1(content)});
    std.debug.print("Part 2: {}\n", .{try part2(content)});
}
