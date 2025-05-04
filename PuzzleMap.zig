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

pub const Distance = struct {
    row: isize,
    col: isize,
};

test Point {
    const p1 = Point{ .row = 3, .col = 5 };
    const p2 = Point{ .row = 2, .col = 1 };

    const dist = p1.distanceTo(p2);

    try std.testing.expectEqual(Distance{ .row = -1, .col = -4 }, dist);
    try std.testing.expectEqual(p2, p1.addDistance(dist));
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
    const data = "abc\ndef\nghi\n";

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
