const std = @import("std");
const extras = @import("extras");
const PuzzleMap = extras.PuzzleMap;
const Point = PuzzleMap.Point;
const Direction = PuzzleMap.Direction;
const Distance = PuzzleMap.Distance;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const puzzle_input = try extras.readFileFromCmdArg(alloc);
    defer alloc.free(puzzle_input);

    const cost = try totalFencePrice(puzzle_input, alloc);
    std.debug.print("part 1: {}\n", .{cost});
}

test "part 1" {
    const alloc = std.testing.allocator;
    try extras.runAocTest("src/day12/test1.in", u64, totalFencePrice, alloc);
    try extras.runAocTest("src/day12/test2.in", u64, totalFencePrice, alloc);
    try extras.runAocTest("src/day12/test3.in", u64, totalFencePrice, alloc);
}

fn totalFencePrice(data: []const u8, alloc: std.mem.Allocator) !u64 {
    const farm = PuzzleMap.init(data);

    var visited_underlying = try alloc.alloc(bool, farm.bounds.row * farm.bounds.col);
    defer alloc.free(visited_underlying);
    @memset(visited_underlying, false);
    var visited: [][]bool = try alloc.alloc([]bool, farm.bounds.row);
    defer alloc.free(visited);
    for (visited, 0..) |*row, idx| {
        row.* = visited_underlying[idx * farm.bounds.col .. (idx + 1) * farm.bounds.col];
    }

    var plot_queue = try std.ArrayList(Point).initCapacity(alloc, visited_underlying.len);
    defer plot_queue.deinit();

    var total_fence_cost: u64 = 0;
    for (0..farm.bounds.row) |row| {
        for (0..farm.bounds.col) |col| {
            if (visited[row][col]) {
                continue;
            }

            var area: u64 = 0;
            var perimeter: u64 = 0;
            const crop = farm.atPointAssumeInside(Point{ .row = row, .col = col });
            plot_queue.appendAssumeCapacity(Point{ .row = row, .col = col });

            while (plot_queue.pop()) |point| {
                if (visited[point.row][point.col]) {
                    continue;
                }

                area += 1;
                visited[point.row][point.col] = true;

                const adjacent = [_]?Point{
                    point.stepInDirection(.up),
                    point.stepInDirection(.down),
                    point.stepInDirection(.left),
                    point.stepInDirection(.right),
                };

                for (adjacent) |maybe_adj_plot| {
                    if (!farm.isPointInside(maybe_adj_plot)) {
                        perimeter += 1;
                        continue;
                    }

                    const adj_plot = maybe_adj_plot.?;

                    const adj_crop = farm.atPointAssumeInside(adj_plot);
                    if (adj_crop != crop) {
                        perimeter += 1;
                        continue;
                    }

                    // keep iterating over plots of the same crop
                    plot_queue.appendAssumeCapacity(adj_plot);
                }
            }

            // std.debug.print("crop: {c}, area: {d:4}, peri: {d:4}\n", .{ crop, area, perimeter });
            total_fence_cost += area * perimeter;
        }
    }

    return total_fence_cost;
}
