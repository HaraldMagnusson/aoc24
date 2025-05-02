const std = @import("std");
const extras = @import("extras");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const puzzle_input = extras.readFileFromCmdArg(alloc) catch |err| switch (err) {
        error.NoArgsGiven => return,
        error.FileNotFound => return,
        else => return err,
    };
    defer alloc.free(puzzle_input);

    std.debug.print(
        "\nPart 1: sum of valid calibrations: {d}\n\n",
        .{try calcSumOfValidCalibrations(puzzle_input, alloc)},
    );
}

fn calcSumOfValidCalibrations(data: []const u8, alloc: std.mem.Allocator) !u64 {
    var iter = std.mem.splitScalar(u8, data, '\n');

    var valid_result_sum: u64 = 0;
    while (iter.next()) |row| {
        if (row.len == 0) continue;

        const cal = try Calibration.parseFromStr(row, alloc);
        defer cal.deinit();
        if (cal.isValid()) {
            valid_result_sum += cal.result;
        }
    }
    return valid_result_sum;
}

test "day7 aoc input" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    try extras.runAocTest(
        "day7/test1.input",
        u64,
        &calcSumOfValidCalibrations,
        arena.allocator(),
    );
}

const Operator = enum { add, mult };
const operators = [_]Operator{ .add, .mult };

const Calibration = struct {
    result: u64,
    values: []const u64,
    alloc: std.mem.Allocator,

    fn parseFromStr(str: []const u8, alloc: std.mem.Allocator) !Calibration {
        var str_iter = std.mem.splitAny(u8, str, ": ");

        const cal_result_str = str_iter.first();
        const cal_result = try std.fmt.parseInt(u64, cal_result_str, 10);
        _ = str_iter.next(); // skip empty entry coming from ": "

        var result_list = std.ArrayList(u64).init(alloc);

        while (str_iter.next()) |item_str| {
            const item_int = try std.fmt.parseInt(u64, item_str, 10);
            try result_list.append(item_int);
        }

        return Calibration{
            .result = cal_result,
            .values = try result_list.toOwnedSlice(),
            .alloc = alloc,
        };
    }

    fn deinit(self: Calibration) void {
        self.alloc.free(self.values);
    }

    fn isValid(self: Calibration) bool {
        const start_value = self.values[0];

        var is_valid = false;
        for (operators) |operator| {
            is_valid = is_valid or self.isValidRecursiveCalc(operator, 1, start_value);
        }
        return is_valid;
    }

    fn isValidRecursiveCalc(
        self: Calibration,
        op: Operator,
        depth: usize,
        cumulative_result: u64,
    ) bool {
        if (depth == self.values.len) {
            return cumulative_result == self.result;
        }

        const current_result = switch (op) {
            .add => cumulative_result + self.values[depth],
            .mult => cumulative_result * self.values[depth],
        };

        var is_valid = false;
        for (operators) |operator| {
            is_valid = is_valid or self.isValidRecursiveCalc(
                operator,
                depth + 1,
                current_result,
            );
        }
        return is_valid;
    }
};

test Calibration {
    const input = "3420: 81 42 13";
    const cal = try Calibration.parseFromStr(input, std.testing.allocator);
    defer std.testing.allocator.free(cal.values);

    try std.testing.expectEqual(3420, cal.result);
    try std.testing.expectEqualSlices(u64, &[_]u64{ 81, 42, 13 }, cal.values);

    try std.testing.expectEqual(false, cal.isValid());
}
