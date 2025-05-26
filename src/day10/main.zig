const std = @import("std");
const extras = @import("extras");
const PuzzleMap = extras.PuzzleMap;
const Point = PuzzleMap.Point;
const Distance = PuzzleMap.Distance;
const Direction = PuzzleMap.Direction;

test countTrailHeads {
    const input_path = "src/day10/test1.input";
    const alloc = std.testing.allocator;
    try extras.runAocTest(input_path, u64, countTrailHeads, alloc);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try extras.readFileFromCmdArg(alloc);
    defer alloc.free(input);

    const trail_count = try countTrailHeads(input, alloc);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("part1: {}\n", .{trail_count});
}

fn countTrailHeads(input: []const u8, alloc: std.mem.Allocator) !u64 {
    const puzzle = PuzzleMap.init(input);
    var trailMap = std.AutoHashMap(Point, void).init(alloc);
    defer trailMap.deinit();

    var trail_count: u64 = 0;
    for (0..puzzle.bounds.row) |row| {
        for (0..puzzle.bounds.col) |col| {
            if (puzzle.atIndex(row, col) != '0') continue;

            try findTrails(puzzle, Point{ .row = row, .col = col }, &trailMap);
            trail_count += trailMap.count();
            trailMap.clearRetainingCapacity();
        }
    }

    return trail_count;
}

fn findTrails(puzzle: PuzzleMap, point: Point, trailMap: *std.AutoHashMap(Point, void)) !void {
    const current_val = puzzle.atPoint(point).?;

    if (current_val == '9') {
        // trail found
        try trailMap.put(point, {});
    }

    const steps = [_]Distance{
        Direction.up.toDistance(),
        Direction.down.toDistance(),
        Direction.left.toDistance(),
        Direction.right.toDistance(),
    };

    for (steps) |step| {
        const next_point = point.addDistance(step);
        if (next_point == null) {
            continue;
        }

        const next_val = puzzle.atPoint(next_point.?);
        if (next_val == null) {
            continue;
        }

        // std.debug.print("next: {c}, prev: {c}\n", .{ next_val.?, current_val });
        if (next_val.? == current_val + 1) {
            try findTrails(puzzle, next_point.?, trailMap);
        }
    }
}
