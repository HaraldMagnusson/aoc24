const std = @import("std");
const extras = @import("extras");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try extras.readFileFromCmdArg(alloc);
    defer alloc.free(input);

    const stone_count = try countStonesAfterBlinking(input, alloc);
    std.debug.print("part 1: {d}\n", .{stone_count});
}

test "part1" {
    const input_file = "src/day11/test1.in";
    const alloc = std.testing.allocator;
    try extras.runAocTest(input_file, u64, countStonesAfterBlinking, alloc);
}

fn countStonesAfterBlinking(data: []const u8, alloc: std.mem.Allocator) !u64 {
    var list = try parseInput(data, alloc);
    defer list.deinit();

    const total_blinks = 25;
    for (0..total_blinks) |_| {
        list = try blink(&list, alloc);
    }

    return list.items.len;
}

fn parseInput(data: []const u8, alloc: std.mem.Allocator) !std.ArrayList(u64) {
    var stone_iterator = std.mem.splitAny(u8, data, " \n");
    var stone_list = std.ArrayList(u64).init(alloc);
    errdefer stone_list.deinit();

    while (stone_iterator.next()) |stone| {
        if (stone.len == 0) continue;

        const number_base = 10;
        const stone_value = try std.fmt.parseInt(u64, stone, number_base);
        try stone_list.append(stone_value);
    }

    return stone_list;
}

/// takes ownership of passed list and returns a new one
fn blink(stones: *std.ArrayList(u64), alloc: std.mem.Allocator) !std.ArrayList(u64) {
    var new_stones = std.ArrayList(u64).init(alloc);
    defer stones.deinit();

    for (stones.items) |stone| {
        if (stone == 0) {
            try new_stones.append(1);
            continue;
        }

        const stone_float: f64 = @floatFromInt(stone);
        const digits: u64 = @intFromFloat(@floor(@log10(stone_float)) + 1);
        if (@mod(digits, 2) == 0) {
            const split_digits = digits / 2;
            const split_factor = try std.math.powi(u64, 10, split_digits);
            const left_stone = stone / split_factor;
            const right_stone = @mod(stone, split_factor);

            try new_stones.append(left_stone);
            try new_stones.append(right_stone);

            continue;
        }

        try new_stones.append(stone * 2024);
    }

    return new_stones;
}
