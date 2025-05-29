const std = @import("std");
const extras = @import("extras");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try extras.readFileFromCmdArg(alloc);
    defer alloc.free(input);

    const stone_count = try countStonesAfterBlinking(input, alloc);
    std.debug.print("total stones after blinking: {d}\n", .{stone_count});
}

const max_blinks = 75;

test "part1" {
    const input_file = "src/day11/test1.in";
    const alloc = std.testing.allocator;
    try extras.runAocTest(input_file, u64, countStonesAfterBlinking, alloc);
}

fn countStonesAfterBlinking(data: []const u8, alloc: std.mem.Allocator) !u64 {
    const start_time = std.time.microTimestamp();
    var stone_iterator = std.mem.splitAny(u8, data, " \n");

    // cache for storing stone at depth -> resulting stone count
    var cache = std.AutoHashMap(Stone, u64).init(alloc);
    try cache.ensureTotalCapacity(200000);
    defer cache.deinit();

    // const total_blinks = max_depth;
    var total_count: u64 = 0;
    while (stone_iterator.next()) |stone_str| {
        if (stone_str.len == 0) {
            continue;
        }

        const stone_val = try std.fmt.parseUnsigned(u64, stone_str, 10);

        const start_time_stone = std.time.microTimestamp();
        total_count += try blink(.{ .val = stone_val, .blinks = 0 }, &cache);
        const stop_time_stone = std.time.microTimestamp();
        std.debug.print(
            "stone {d:10} took {} µs\n",
            .{ stone_val, stop_time_stone - start_time_stone },
        );
    }

    const stop_time = std.time.microTimestamp();
    std.debug.print("total time: {} µs\n", .{stop_time - start_time});

    std.debug.print("cache items: {}\n", .{cache.count()});
    return total_count;
}

const Stone = struct {
    val: u64,
    blinks: usize,
};

fn blink(stone: Stone, cache: *std.AutoHashMap(Stone, u64)) !u64 {
    if (stone.blinks == max_blinks) {
        return 1;
    }

    const cached_count = cache.get(stone);
    if (cached_count) |count| {
        return count;
    }

    const new_blinks = stone.blinks + 1;
    var count: u64 = 0;
    if (stone.val == 0) {
        count = try blink(.{ .val = 1, .blinks = new_blinks }, cache);
    } else {
        const digits = countDigits(stone.val);
        if (digits & 1 == 0) {
            const new_stones = splitInt(stone.val, digits);
            const left_stone = Stone{ .val = new_stones.left, .blinks = new_blinks };
            const right_stone = Stone{ .val = new_stones.right, .blinks = new_blinks };
            count = try blink(left_stone, cache) + try blink(right_stone, cache);
        } else {
            count = try blink(.{ .val = stone.val * 2024, .blinks = new_blinks }, cache);
        }
    }

    try cache.put(stone, count);
    return count;
}

inline fn countDigits(num: u64) u32 {
    var digits: u32 = 0;
    var tmp_val = num;
    while (tmp_val > 0) : (tmp_val /= 10) {
        digits += 1;
    }
    return digits;
}

inline fn splitInt(num: u64, digits: u32) struct { left: u64, right: u64 } {
    const split_factor: u32 = std.math.powi(u32, 10, digits / 2) catch unreachable;

    const left: u64 = num / split_factor;
    const right: u64 = @mod(num, split_factor);

    return .{ .left = left, .right = right };
}

test countDigits {
    try std.testing.expectEqual(1, countDigits(1));
    try std.testing.expectEqual(2, countDigits(12));
    try std.testing.expectEqual(3, countDigits(123));
    try std.testing.expectEqual(4, countDigits(1234));
    try std.testing.expectEqual(4, countDigits(1000));
    try std.testing.expectEqual(4, countDigits(9999));
    try std.testing.expectEqual(5, countDigits(10000));
}
