const std = @import("std");
const extras = @import("extras");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const input_file = try extras.readFileFromCmdArg(alloc);
    defer alloc.free(input_file);

    std.debug.print("part1: {d}\n", .{try compactDiskAndCalcChecksum(input_file, alloc)});
    std.debug.print("part2: {d}\n", .{try compactDiskAndCalcChecksumChunks(input_file, alloc)});
}

test "part 1 test" {
    const test_filepath = "src/day9/test1.input";
    const alloc = std.testing.allocator;
    try extras.runAocTest(test_filepath, u64, compactDiskAndCalcChecksum, alloc);
}

test "part 2 test" {
    const test_filepath = "src/day9/test2.input";
    const alloc = std.testing.allocator;
    try extras.runAocTest(test_filepath, u64, compactDiskAndCalcChecksumChunks, alloc);
}

test "part 1 logic test" {
    const disk_map = "3142101";
    const expected_disk = &[_]Block{ 0, 0, 0, null, 1, 1, 1, 1, null, null, 2, 3 };

    const alloc = std.testing.allocator;
    const disk = try unwrapDiskMap(disk_map, alloc);
    defer alloc.free(disk);

    try std.testing.expectEqualSlices(Block, expected_disk, disk);

    const expected_compacted_disk = &[_]Block{ 0, 0, 0, 3, 1, 1, 1, 1, 2 };
    const compacted_disk = compactDisk(disk);
    try std.testing.expectEqualSlices(Block, expected_compacted_disk, compacted_disk);

    try std.testing.expectEqual(47, fsChecksum(compacted_disk));
}

fn compactDiskAndCalcChecksum(disk_map: []const u8, alloc: std.mem.Allocator) !u64 {
    const disk_map_no_nl = for (0..disk_map.len) |idx| {
        if (disk_map[idx] == '\n') {
            break disk_map[0..idx];
        }
    } else disk_map;

    const disk = try unwrapDiskMap(disk_map_no_nl, alloc);
    defer alloc.free(disk);

    const compact_disk = compactDisk(disk);
    return fsChecksum(compact_disk);
}

fn totalBlockCount(disk_map: []const u8) u64 {
    var total_block_count: u64 = 0;
    for (disk_map) |block_count_ch| {
        total_block_count += block_count_ch - '0';
    }
    return total_block_count;
}

const Block = ?u64;

fn unwrapDiskMap(disk_map: []const u8, alloc: std.mem.Allocator) ![]Block {
    const total_block_count = totalBlockCount(disk_map);
    var disk = try alloc.alloc(Block, total_block_count);

    // disk alternates between files and free space
    var file_block = true;
    var disk_idx: usize = 0;
    var file_id: u64 = 0;
    for (disk_map) |block_count_ch| {
        const block_count = block_count_ch - '0';
        for (0..block_count) |_| {
            disk[disk_idx] = if (file_block) file_id else null;
            disk_idx += 1;
        }

        if (file_block) {
            file_id += 1;
        }

        file_block = !file_block;
    }

    return disk;
}

fn compactDisk(disk: []Block) []Block {
    var end_idx: usize = disk.len - 1;
    for (0..disk.len) |idx| {
        if (idx >= end_idx) {
            break;
        }

        if (disk[idx] != null) {
            continue;
        }

        disk[idx] = disk[end_idx];
        disk[end_idx] = null;
        while (disk[end_idx] == null) {
            end_idx -= 1;
        }
    }

    return disk[0 .. end_idx + 1];
}

fn fsChecksum(compacted_disk: []Block) u64 {
    var checksum: u64 = 0;
    for (compacted_disk, 0..) |block, idx| {
        checksum += block.? * idx;
    }
    return checksum;
}

test "part 2 logic test" {
    const disk_map = "2331201";
    // original:   00...111.223
    // compressed: 00322111....
    // chksum: 0 + 0 + 2*3 + 3*2 + 4*2 + 5*1 + 6*1 + 7*1 = 31
    const expected_disk = &[_]File{
        .{ .id = 0, .len = 2, .following_free = 3 },
        .{ .id = 1, .len = 3, .following_free = 1 },
        .{ .id = 2, .len = 2, .following_free = 0 },
        .{ .id = 3, .len = 1, .following_free = 0 },
    };

    const alloc = std.testing.allocator;
    const disk = try parseDiskMapChunks(disk_map, alloc);
    defer alloc.free(disk);
    try std.testing.expectEqualSlices(File, expected_disk, disk);

    const expected_compacted_disk = &[_]File{
        .{ .id = 0, .len = 2, .following_free = 0, .moved = false },
        .{ .id = 3, .len = 1, .following_free = 0, .moved = true },
        .{ .id = 2, .len = 2, .following_free = 0, .moved = true },
        .{ .id = 1, .len = 3, .following_free = 4, .moved = false },
    };
    const compacted_disk = compactDiskKeepChunks(disk);
    try std.testing.expectEqualSlices(File, expected_compacted_disk, compacted_disk);

    try std.testing.expectEqual(38, fsChecksumChunks(compacted_disk));
}

fn compactDiskAndCalcChecksumChunks(disk_map: []const u8, alloc: std.mem.Allocator) !u64 {
    const disk = try parseDiskMapChunks(disk_map, alloc);
    defer alloc.free(disk);

    const compacted_disk = compactDiskKeepChunks(disk);
    return fsChecksumChunks(compacted_disk);
}

const File = struct {
    id: u32,
    len: u8,
    following_free: u8,
    moved: bool = false,
};

fn parseDiskMapChunks(dirty_disk_map: []const u8, alloc: std.mem.Allocator) ![]File {
    const disk_map_str = for (dirty_disk_map, 0..) |disk_map_ch, idx| {
        if (disk_map_ch == '\n') {
            break dirty_disk_map[0..idx];
        }
    } else dirty_disk_map;

    var disk_map = try alloc.alloc(File, (disk_map_str.len + 1) / 2);

    var disk_str_idx: usize = 0;
    var disk_map_idx: usize = 0;
    var chunk_id: u32 = 0;
    while (disk_str_idx < disk_map_str.len) : (disk_str_idx += 2) {
        const len = disk_map_str[disk_str_idx] - '0';

        // handle disk map ending with a file
        if (disk_map_str.len - disk_str_idx == 1) {
            disk_map[disk_map_idx] = .{
                .id = chunk_id,
                .len = len,
                .following_free = 0,
            };
            break;
        }

        const free_len = disk_map_str[disk_str_idx + 1] - '0';

        disk_map[disk_map_idx] = .{
            .id = chunk_id,
            .len = len,
            .following_free = free_len,
        };

        chunk_id += 1;
        disk_map_idx += 1;
    }
    return disk_map;
}

fn compactDiskKeepChunks(disk: []File) []File {
    var disk_idx_to_move: usize = disk.len - 1;
    while (disk_idx_to_move > 0) : (disk_idx_to_move -= 1) {
        // only move files once
        if (disk[disk_idx_to_move].moved) continue;

        // find where file fits
        const required_space = disk[disk_idx_to_move].len;
        const idx_with_space: ?usize =
            for (disk, 0..) |chunk, idx| {
                // no spot found
                if (idx >= disk_idx_to_move) break null;

                // spot found
                if (chunk.following_free >= required_space) break idx;
            } else null;

        if (idx_with_space == null) continue;

        var file_to_move = disk[disk_idx_to_move];

        // fix free spaces
        if (disk_idx_to_move == disk.len - 1) {
            disk[disk_idx_to_move - 1].following_free = 0;
        } else {
            disk[disk_idx_to_move - 1].following_free += file_to_move.len + file_to_move.following_free;
        }

        file_to_move.following_free = disk[idx_with_space.?].following_free - file_to_move.len;
        disk[idx_with_space.?].following_free = 0;

        // shuffle files over and insert
        var idx: usize = disk_idx_to_move;
        while (idx > idx_with_space.? + 1) : (idx -= 1) {
            disk[idx] = disk[idx - 1];
        }
        disk_idx_to_move += 1;
        file_to_move.moved = true;
        disk[idx_with_space.? + 1] = file_to_move;
    }

    return disk;
}

fn fsChecksumChunks(disk: []File) u64 {
    var checksum: u64 = 0;
    var block_pos: usize = 0;

    for (disk) |file| {
        for (0..file.len) |_| {
            checksum += file.id * block_pos;
            block_pos += 1;
        }
        block_pos += file.following_free;
    }

    return checksum;
}
