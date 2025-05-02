const std = @import("std");
const extras = @import("extras");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input_file = extras.readFileFromCmdArg(allocator) catch |err| switch (err) {
        error.NoArgsGiven => return,
        error.FileNotFound => return,
        else => return err,
    };
    defer allocator.free(input_file);
    var iter = std.mem.splitScalar(u8, input_file, '\n');

    while (iter.next()) |row| {
        std.debug.print("{s}\n", .{row});
    }
}

fn testFunc(data: []const u8) !i64 {
    _ = data;
    return 3749;
    //return 42;
}

test "day7 aoc input" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    try extras.runAocTest(
        "day7/test1.input",
        i64,
        &testFunc,
        arena.allocator(),
    );
}

const Operator = enum { add, mult };
const operators: []Operator = .{ .add, .mult };

const Calibration = struct {
    result: u64,
    values: []const u64,

    fn parseFromStr(str: []const u8, allocator: std.mem.Allocator) !Calibration {
        var str_iter = std.mem.splitAny(u8, str, ": ");

        const cal_result_str = str_iter.first();
        const cal_result = try std.fmt.parseInt(u64, cal_result_str, 10);
        _ = str_iter.next(); // skip empty entry coming from ": "

        var result_list = std.ArrayList(u64).init(allocator);

        while (str_iter.next()) |item_str| {
            const item_int = try std.fmt.parseInt(u64, item_str, 10);
            try result_list.append(item_int);
        }

        return Calibration{
            .result = cal_result,
            .values = try result_list.toOwnedSlice(),
        };
    }
};

test Calibration {
    const input = "3420: 81 42 13";
    const cal = try Calibration.parseFromStr(input, std.testing.allocator);
    defer std.testing.allocator.free(cal.values);

    try std.testing.expectEqual(3420, cal.result);
    try std.testing.expectEqualSlices(u64, &[_]u64{ 81, 42, 13 }, cal.values);
}
