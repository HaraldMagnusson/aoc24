const std = @import("std");
const extras = @import("extras");

const PuzzleMap = extras.PuzzleMap;
const Point = PuzzleMap.Point;

const PositionList = std.ArrayList(Point);
const PositionListMap = std.AutoHashMap(u8, PositionList);
const AntinodeMap = std.AutoHashMap(Point, void);

test "part 1 sample input" {
    const test_file = "day8/test1.input";

    try extras.runAocTest(test_file, u64, &countUniqueAntinodes, std.testing.allocator);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const puzzle_input = try extras.readFileFromCmdArg(alloc);
    const unique_antinodes = try countUniqueAntinodes(puzzle_input, alloc);

    var print_buffer: [128]u8 = undefined;
    const unique_antinodes_msg = try std.fmt.bufPrint(
        print_buffer[0..],
        "{d}\n",
        .{unique_antinodes},
    );
    _ = try std.io.getStdOut().write(unique_antinodes_msg);
}

fn countUniqueAntinodes(data: []const u8, alloc: std.mem.Allocator) !u64 {
    const map = PuzzleMap.init(data);

    var position_list_map = PositionListMap.init(alloc);
    defer {
        var pos_list_iter = position_list_map.iterator();
        while (pos_list_iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        position_list_map.deinit();
    }

    // gather the positions of all antennas with a certain frequency
    // in the list for that frequency
    for (0..map.bounds.row) |row| {
        for (0..map.bounds.col) |col| {
            const ch = map.atIndexAssumeInside(row, col);
            if (!isFrequency(ch)) {
                continue;
            }

            const point = Point{ .row = row, .col = col };

            var maybe_position_list = position_list_map.get(ch);

            if (maybe_position_list) |*pos_list| {
                try pos_list.append(point);
                try position_list_map.put(ch, pos_list.*);
            } else {
                var new_list = PositionList.init(alloc);
                try new_list.append(point);
                try position_list_map.put(ch, new_list);
            }
        }
    }

    var antinode_map = AntinodeMap.init(alloc);
    defer antinode_map.deinit();

    var pos_list_map_iter = position_list_map.iterator();
    while (pos_list_map_iter.next()) |pos_list_map_entry| {
        const pos_list = pos_list_map_entry.value_ptr.*;
        try findAntinodes(map, pos_list, &antinode_map);
    }

    return antinode_map.count();
}

fn findAntinodes(map: PuzzleMap, position_list: PositionList, antinode_map: *AntinodeMap) !void {
    for (0..position_list.items.len - 1) |p1_idx| {
        for (position_list.items[p1_idx + 1 ..]) |p2| {
            const p1 = position_list.items[p1_idx];

            const dist = p1.distanceTo(p2);

            const antinode1 = p1.subtractDistance(dist);
            if (antinode1) |point| {
                if (map.atPoint(point) != null) {
                    try antinode_map.put(point, {});
                }
            }
            const antinode2 = p2.addDistance(dist);
            if (antinode2) |point| {
                if (map.atPoint(point) != null) {
                    try antinode_map.put(point, {});
                }
            }
        }
    }
}

fn isFrequency(ch: u8) bool {
    return switch (ch) {
        '0'...'9' => true,
        'a'...'z' => true,
        'A'...'Z' => true,
        else => false,
    };
}
