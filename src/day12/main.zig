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
    std.debug.print("part 2: {}\n", .{cost});
}

test "part 2" {
    const alloc = std.testing.allocator;
    try extras.runAocTest("src/day12/test4.in", u64, totalFencePrice, alloc);
    try extras.runAocTest("src/day12/test5.in", u64, totalFencePrice, alloc);
    try extras.runAocTest("src/day12/test6.in", u64, totalFencePrice, alloc);
    try extras.runAocTest("src/day12/test7.in", u64, totalFencePrice, alloc);
    try extras.runAocTest("src/day12/test8.in", u64, totalFencePrice, alloc);
}

const Side = struct {
    point: Point,
    dir: Direction,
};

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

    var sides = std.AutoHashMap(Side, void).init(alloc);
    defer sides.deinit();

    var total_fence_cost: u64 = 0;
    for (0..farm.bounds.row) |row| {
        for (0..farm.bounds.col) |col| {
            if (visited[row][col]) {
                continue;
            }

            var area: u64 = 0;
            var side_count: u64 = 0;
            const crop = farm.atPointAssumeInside(Point{ .row = row, .col = col });
            plot_queue.appendAssumeCapacity(Point{ .row = row, .col = col });
            sides.clearRetainingCapacity();

            // step through all plots in this region
            while (plot_queue.items.len > 0) {
                const point = plot_queue.orderedRemove(0);

                if (visited[point.row][point.col]) {
                    continue;
                }

                area += 1;
                visited[point.row][point.col] = true;

                const dirs = [_]Direction{ .up, .left, .right, .down };

                for (dirs) |dir| {
                    const adj_plot = point.stepInDirection(dir);
                    // edge of region found if next plot is outside farm
                    if (!farm.isPointInside(adj_plot)) {
                        try sides.put(Side{ .point = point, .dir = dir }, {});
                        if (!sideFoundPreviously(farm, point, dir, sides)) {
                            side_count += 1;
                        }
                        continue;
                    }

                    // edge of region found if next plot has different crop
                    const adj_crop = farm.atPointAssumeInside(adj_plot.?);
                    if (adj_crop != crop) {
                        try sides.put(Side{ .point = point, .dir = dir }, {});
                        if (!sideFoundPreviously(farm, point, dir, sides)) {
                            side_count += 1;
                        }
                        continue;
                    }

                    // keep iterating over plots of the same crop
                    plot_queue.appendAssumeCapacity(adj_plot.?);
                }
            }

            // a region cannot have an odd side count
            std.debug.assert(side_count & 1 == 0);
            total_fence_cost += area * side_count;
        }
    }

    return total_fence_cost;
}

fn sideFoundPreviously(
    farm: PuzzleMap,
    point: Point,
    dir: Direction,
    sides: std.AutoHashMap(Side, void),
) bool {
    const crop = farm.atPointAssumeInside(point);

    // search perpendicularly to dir for previously seen sides
    const axis_to_search: Direction = switch (dir) {
        .up, .down => .right,
        .left, .right => .up,
        else => unreachable,
    };

    const dirs_to_search: [2]Direction = .{ axis_to_search, axis_to_search.opposite() };
    for (dirs_to_search) |dir_to_search| {
        var search_point = point;
        while (true) {
            // edge of farm
            search_point = search_point.stepInDirection(dir_to_search) orelse break;
            if (!farm.isPointInside(search_point)) {
                break;
            }

            // edge of region => convex corner of region
            const search_crop = farm.atPointAssumeInside(search_point);
            if (search_crop != crop) {
                break;
            }

            // crop continues in direction dir => concave corner of region
            // its okay if this point is outside of the farm => no concave corner
            const opposite_point = search_point.stepInDirection(dir);
            if (opposite_point) |dir_point| {
                const dir_crop = farm.atPoint(dir_point);
                if (dir_crop == crop) {
                    break;
                }
            }

            // have we seen this side before?
            if (sides.contains(Side{ .point = search_point, .dir = dir })) {
                return true;
            }
        }
    }

    return false;
}
