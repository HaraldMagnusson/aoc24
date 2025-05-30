//! A data type used to interpret a puzzle input string from Advent of Code
//! as a 2D array of characters. The puzzle input string must a sequence of
//! rows of equal length, each ending with a newline (\n).
//!
//! # Example usage:
//! ```zig
//!     const PuzzleMap = @import("PuzzleMap.zig");
//!
//!     // the last row must also end with a \n
//!     const data =
//!         \\abc
//!         \\def
//!         \\ghi
//!         \\
//!     ;
//!     const map = PuzzleMap.init(data);
//!
//!     // access data
//!     const p0 = PuzzleMap.Point{ .row = 1, .col = 2 };
//!     try std.testing.expectEqual('f', map.atPoint(p0));
//!
//!     // step around
//!     const down = PuzzleMap.Distance{ .row = 1, .col = 0 };
//!     const p1 = p0.addDistance(down).?; // {2, 2}
//!     try std.testing.expectEqual('i', map.atPoint(p1));
//!
//!     // find minimal step in a given direction
//!     const p2 = PuzzleMap.Point{ .row = 0, .col = 0 };
//!     const direction = p2.distanceTo(p1).pseudoUnitVector();
//!     try std.testing.expectEqual(PuzzleMap.Distance{ .row = 1, .col = 1 }, direction);
//! ```

const std = @import("std");

map: []const u8,
bounds: Point,

pub const Point = struct {
    row: usize,
    col: usize,

    pub fn distanceTo(self: Point, other: Point) Distance {
        return .{
            .row = @as(isize, @intCast(other.row)) - @as(isize, @intCast(self.row)),
            .col = @as(isize, @intCast(other.col)) - @as(isize, @intCast(self.col)),
        };
    }

    pub fn addDistance(self: Point, dist: Distance) ?Point {
        const row: isize = @as(isize, @intCast(self.row)) + dist.row;
        const col: isize = @as(isize, @intCast(self.col)) + dist.col;

        if (row < 0) {
            return null;
        }
        if (col < 0) {
            return null;
        }

        return .{
            .row = @intCast(row),
            .col = @intCast(col),
        };
    }

    pub fn subtractDistance(self: Point, dist: Distance) ?Point {
        const inverted_dist = Distance{ .row = -dist.row, .col = -dist.col };
        return self.addDistance(inverted_dist);
    }
};

test Point {
    const p1 = Point{ .row = 3, .col = 5 };
    const p2 = Point{ .row = 2, .col = 1 };

    const dist = p1.distanceTo(p2);

    try std.testing.expectEqual(Distance{ .row = -1, .col = -4 }, dist);
    try std.testing.expectEqual(p2, p1.addDistance(dist));
}

pub const Distance = struct {
    row: isize,
    col: isize,

    pub fn pseudoUnitVector(self: Distance) Distance {
        const gcd = greatestCommonDenominator(isize, self.row, self.col);
        return .{ .row = @divExact(self.row, gcd), .col = @divExact(self.col, gcd) };
    }

    fn greatestCommonDenominator(T: type, a: T, b: T) T {
        comptime std.debug.assert(@typeInfo(T) == .int);

        if (a == b) return a;

        var previous: T = a;
        var current: T = b;
        var next: T = undefined;

        if (@typeInfo(T).int.signedness == .signed) {
            previous = @intCast(@abs(previous));
            current = @intCast(@abs(current));
        }

        if (current > previous) {
            const tmp = previous;
            previous = current;
            current = tmp;
        }

        while (current > 0) {
            next = @mod(previous, current);
            previous = current;
            current = next;
        }

        return previous;
    }
};

test Distance {
    try std.testing.expectEqual(21, Distance.greatestCommonDenominator(u32, 1071, 462));
    try std.testing.expectEqual(21, Distance.greatestCommonDenominator(i32, 1071, -462));
    try std.testing.expectEqual(21, Distance.greatestCommonDenominator(i32, -1071, 462));
    try std.testing.expectEqual(21, Distance.greatestCommonDenominator(i32, -1071, -462));

    try std.testing.expectEqual(
        Distance{ .row = 1, .col = -3 },
        Distance.pseudoUnitVector(.{ .row = 3, .col = -9 }),
    );
}

pub const Direction = enum {
    up,
    up_left,
    up_right,
    down,
    down_left,
    down_right,
    right,
    left,

    pub fn toDistance(self: Direction) Distance {
        switch (self) {
            .up => return Distance{ .row = -1, .col = 0 },
            .up_left => return Distance{ .row = -1, .col = -1 },
            .up_right => return Distance{ .row = -1, .col = 1 },
            .down => return Distance{ .row = 1, .col = 0 },
            .down_left => return Distance{ .row = 1, .col = -1 },
            .down_right => return Distance{ .row = 1, .col = 1 },
            .right => return Distance{ .row = 0, .col = 1 },
            .left => return Distance{ .row = 0, .col = -1 },
        }
    }
};

test Direction {
    const p1 = Point{ .row = 1, .col = 1 };
    const p2 = p1.addDistance(Direction.down.toDistance());
    try std.testing.expectEqual(Point{ .row = 2, .col = 1 }, p2.?);
}

pub fn init(data: []const u8) @This() {
    var rows: usize = 0;
    var cols: usize = 0;

    var cols_found = false;
    for (data, 0..) |ch, idx| {
        if (ch != '\n') {
            continue;
        }

        if (!cols_found) {
            cols = idx;
            cols_found = true;
            // assert that the data is a rectangle
            std.debug.assert(@mod(data.len, cols + 1) == 0);
        } else {
            std.debug.assert(@mod(idx, cols + 1) == cols);
        }

        rows += 1;
    }
    const bounds = Point{ .row = rows, .col = cols };

    return @This(){ .map = data, .bounds = bounds };
}

pub fn atPoint(self: @This(), point: Point) ?u8 {
    return self.atIndex(point.row, point.col);
}

pub fn atPointAssumeInside(self: @This(), point: Point) u8 {
    const idx = point.row * (self.bounds.col + 1) + point.col;
    return self.map[idx];
}

pub fn atIndex(self: @This(), row: usize, col: usize) ?u8 {
    if (row >= self.bounds.row) {
        return null;
    }
    if (col >= self.bounds.col) {
        return null;
    }
    const idx = row * (self.bounds.col + 1) + col;
    return self.map[idx];
}

pub fn atIndexAssumeInside(self: @This(), row: usize, col: usize) u8 {
    const idx = row * (self.bounds.col + 1) + col;
    return self.map[idx];
}

pub fn isDistanceFromPointInside(self: @This(), dist: Distance, point: Point) bool {
    const row: isize = @as(isize, @intCast(point.row)) + dist.row;
    const col: isize = @as(isize, @intCast(point.col)) + dist.col;

    if (row < 0) {
        return false;
    }
    if (row >= self.bounds.row) {
        return false;
    }
    if (col < 0) {
        return false;
    }
    if (col >= self.bounds.col) {
        return false;
    }

    return true;
}

test "PuzzleMap" {
    // the last row must also end with a \n
    const data =
        \\abc
        \\def
        \\ghi
        \\
    ;

    const map = @This().init(data);
    try std.testing.expectEqual('a', map.atIndexAssumeInside(0, 0));
    try std.testing.expectEqual('d', map.atIndexAssumeInside(1, 0));
    try std.testing.expectEqual('b', map.atIndexAssumeInside(0, 1));
    try std.testing.expectEqual('h', map.atIndex(2, 1));
    try std.testing.expectEqual('i', map.atIndex(2, 2));
    try std.testing.expectEqual(null, map.atIndex(3, 0));
    try std.testing.expectEqual(null, map.atIndex(0, 3));
    try std.testing.expectEqual(null, map.atIndex(42, 42));

    try std.testing.expectEqual('a', map.atPointAssumeInside(Point{ .row = 0, .col = 0 }));
    try std.testing.expectEqual('d', map.atPointAssumeInside(Point{ .row = 1, .col = 0 }));
    try std.testing.expectEqual('b', map.atPointAssumeInside(Point{ .row = 0, .col = 1 }));
    try std.testing.expectEqual('h', map.atPoint(Point{ .row = 2, .col = 1 }));
    try std.testing.expectEqual('i', map.atPoint(Point{ .row = 2, .col = 2 }));
    try std.testing.expectEqual(null, map.atPoint(Point{ .row = 3, .col = 0 }));
    try std.testing.expectEqual(null, map.atPoint(Point{ .row = 0, .col = 3 }));
    try std.testing.expectEqual(null, map.atPoint(Point{ .row = 42, .col = 42 }));
}

test "example" {
    const PuzzleMap = @import("PuzzleMap.zig");

    // the last row must also end with a \n
    const data =
        \\abc
        \\def
        \\ghi
        \\
    ;
    const map = PuzzleMap.init(data);

    // access data
    const p0 = PuzzleMap.Point{ .row = 1, .col = 2 };
    try std.testing.expectEqual('f', map.atPoint(p0));

    // step around
    const down = PuzzleMap.Distance{ .row = 1, .col = 0 };
    const p1 = p0.addDistance(down).?; // {2, 2}
    try std.testing.expectEqual('i', map.atPoint(p1));

    // find minimal step in a given direction
    const p2 = PuzzleMap.Point{ .row = 0, .col = 0 };
    const direction = p2.distanceTo(p1).pseudoUnitVector();
    try std.testing.expectEqual(PuzzleMap.Distance{ .row = 1, .col = 1 }, direction);
}
