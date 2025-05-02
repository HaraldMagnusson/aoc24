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
    //return 3749;
    return 42;
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
