const std = @import("std");

/// reads and returns a maximum of 100 MiB from the file given by the first cmd line argument
pub fn readFileFromCmdArg(allocator: std.mem.Allocator) ![]const u8 {
    var args = try std.process.argsWithAllocator(allocator);
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
    return try input_file.readToEndAlloc(allocator, max_buf_size);
}
