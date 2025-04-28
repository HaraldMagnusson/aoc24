const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var iter = getFileIteratorFromLaunchArg(&arena) catch |err| switch (err) {
        error.NoArgsGiven => {
            std.debug.print("No filename given\n", .{});
            return err;
        },
        else => return err,
    };

    while (iter.next()) |row| {
        std.debug.print("{s}\n", .{row});
    }
}

/// Returns an interator that iterates through each line the file
/// specified by the first launch argument.
/// Uses arena allocator to not need to free file content buffer.
/// Reads a maximum of 100 MiB from file.
pub fn getFileIteratorFromLaunchArg(
    arena: *std.heap.ArenaAllocator,
) !std.mem.SplitIterator(u8, .scalar) {
    var args = std.process.args();
    defer args.deinit();

    _ = args.skip(); // skip launch command

    const filename = args.next() orelse {
        return error.NoArgsGiven;
    };

    const input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    const allocator = arena.allocator();
    const max_buf_size = 100 * 1024 * 1024;
    const content = try input_file.readToEndAlloc(allocator, max_buf_size);

    return std.mem.splitScalar(u8, content, '\n');
}
