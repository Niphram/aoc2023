const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub fn Grid(comptime Tile: anytype) type {
    return struct {
        const Self = @This();

        width: usize,
        height: usize,
        tiles: []Tile,

        allocator: Allocator,

        pub fn init(allocator: Allocator, width: usize, height: usize, value: Tile) !Self {
            const tiles = try allocator.alloc(Tile, width * height);
            @memset(tiles, value);

            return .{
                .width = width,
                .height = height,
                .tiles = tiles,
                .allocator = allocator,
            };
        }

        pub fn initParse(allocator: Allocator, input: []const u8) !Self {
            comptime {
                if (!@hasDecl(Tile, "parse")) @compileError("Tile must have decl parse: fn (u8) Tile.");
                if (@TypeOf(Tile.parse) != fn (u8) Tile) @compileError("Tile.parse must be a fn (u8) Tile.");
            }

            const width = std.mem.indexOfScalar(u8, input, '\n') orelse input.len;
            const height = (input.len + 1) / (width + 1);

            const tiles = try allocator.alloc(Tile, width * height);

            var i: usize = 0;
            var line_iter = std.mem.splitScalar(u8, input, '\n');
            while (line_iter.next()) |line| {
                for (line) |c| {
                    tiles[i] = Tile.parse(c);
                    i += 1;
                }
            }

            return .{
                .width = width,
                .height = height,
                .tiles = tiles,
                .allocator = allocator,
            };
        }

        pub fn get(self: Self, x: usize, y: usize) Tile {
            return self.tiles[y * self.width ..][x];
        }

        pub fn getPtr(self: *Self, x: usize, y: usize) *Tile {
            return &self.tiles[y * self.width ..][x];
        }

        pub fn set(self: *Self, x: usize, y: usize, value: Tile) void {
            self.tiles[y * self.width ..][x] = value;
        }

        pub fn fill(self: *Self, tile: Tile) void {
            @memset(self.tiles, tile);
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.tiles);
        }
    };
}
