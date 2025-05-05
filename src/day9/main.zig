const std = @import("std");
const extras = @import("extras");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const input_file = try extras.readFileFromCmdArg(alloc);
    defer alloc.free(input_file);

    std.debug.print("{d}\n", .{try checksumOfCompactedFs(input_file, alloc)});
}

test "part 1 test" {
    const test_filepath = "src/day9/test1.input";
    const alloc = std.testing.allocator;
    try extras.runAocTest(test_filepath, u64, checksumOfCompactedFs, alloc);
}

fn checksumOfCompactedFs(disk_map: []const u8, alloc: std.mem.Allocator) !u64 {
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

test "unwrap, compact, checksum" {
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

        file_block = file_block != true;
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
