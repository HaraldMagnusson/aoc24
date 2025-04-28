const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    defer args.deinit();

    _ = args.skip();

    const filename = args.next() orelse {
        std.debug.print("No filename given\n", .{});
        return;
    };

    std.debug.print("filename: {s}\n", .{filename});

    const test_file = try std.fs.cwd().openFile(filename, .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const max_buf_size = 1024 * 1024;
    const content = try test_file.readToEndAlloc(allocator, max_buf_size);

    std.debug.print("data:\n{s}\n", .{content});
    // user std.mem.split to get an iterator for file, maybe refactor into a general file reader to use each day/test
}
