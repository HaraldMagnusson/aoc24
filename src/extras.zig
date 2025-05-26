const std = @import("std");
pub const PuzzleMap = @import("PuzzleMap.zig");

/// Reads and returns a maximum of 100 MiB from the file given by
/// the first cmd line argument. Caller owns the returned memory.
pub fn readFileFromCmdArg(alloc: std.mem.Allocator) ![]const u8 {
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.skip(); // skip launch command

    const filename = args.next() orelse {
        std.debug.print("\nNo filename given\n\n", .{});
        return error.NoArgsGiven;
    };

    const input_file = std.fs.cwd().openFile(filename, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("\nInvalid filename: {s}\n\n", .{filename});
            return err;
        },
        else => return err,
    };
    defer input_file.close();

    const max_buf_size = 100 * 1024 * 1024;
    return try input_file.readToEndAlloc(alloc, max_buf_size);
}

/// Runs 'testFunc' on test data in the file given by 'data_filename'.
/// The first row of the file must contain the expected result of
/// 'testFunc'. The remaining rows in the file are passed to 'testFunc'.
/// A maximum of 100 MiB is read from the file.
pub fn runAocTest(
    data_filename: []const u8,
    comptime IntType: type,
    testFunc: *const fn ([]const u8, std.mem.Allocator) anyerror!IntType,
    alloc: std.mem.Allocator,
) !void {
    comptime std.debug.assert(@typeInfo(IntType) == .int);

    const data_file = try std.fs.cwd().openFile(data_filename, .{});
    defer data_file.close();

    const data = try data_file.readToEndAlloc(alloc, 100 * 1024 * 1024);
    defer alloc.free(data);

    var iter = std.mem.splitScalar(u8, data, '\n');

    const result_str = iter.next() orelse return error.EmptyFile;
    const result = try std.fmt.parseInt(IntType, result_str, 10);

    try std.testing.expectEqual(result, testFunc(iter.rest(), alloc));
}
