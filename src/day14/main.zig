const std = @import("std");
const extras = @import("extras");

const Point = struct {
    x: i32 = 0,
    y: i32 = 0,
};

// eww, globals
var robot_room_bounds: Point = .{ .x = 0, .y = 0 };

test "part 1" {
    const ally = std.testing.allocator;
    const test_path = "src/day14/test1.in";
    robot_room_bounds = .{ .x = 11, .y = 7 };

    try extras.runAocTest(test_path, i32, bathroomSafetyFactor, ally);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const ally = gpa.allocator();

    const puzzle_input = try extras.readFileFromCmdArg(ally);
    defer ally.free(puzzle_input);

    robot_room_bounds = .{ .x = 101, .y = 103 };

    // part 1:
    // std.debug.print(
    //     "Bathroom safety factor: {d}\n",
    //     .{bathroomSafetyFactor(puzzle_input, ally) catch unreachable},
    // );

    // part 2:
    std.debug.print(
        "seconds to form christmas tree: {d}\n",
        .{try robotPlotter(puzzle_input, ally)},
    );
}

const Dir = enum { forward, reverse };

const Robot = struct {
    pos: Point,
    vel: Point,

    fn parse(robot_def: []const u8) Robot {
        // format example: "p=0,4 v=3,-3"
        var iter = std.mem.splitAny(u8, robot_def, "=, ");
        var robot = Robot{ .pos = Point{}, .vel = Point{} };

        const base10 = 10;
        _ = iter.first(); // "p"
        robot.pos.x = std.fmt.parseUnsigned(i32, iter.next().?, base10) catch unreachable;
        robot.pos.y = std.fmt.parseUnsigned(i32, iter.next().?, base10) catch unreachable;
        _ = iter.next().?; // "v"
        robot.vel.x = std.fmt.parseInt(i32, iter.next().?, base10) catch unreachable;
        robot.vel.y = std.fmt.parseInt(i32, iter.next().?, base10) catch unreachable;

        return robot;
    }

    fn updatePosition(self: *Robot, dir: Dir) void {
        const dir_factor: i8 = switch (dir) {
            .forward => 1,
            .reverse => -1,
        };

        self.pos.x += self.vel.x * dir_factor;
        self.pos.y += self.vel.y * dir_factor;
        self.pos.x = @mod(self.pos.x, robot_room_bounds.x);
        self.pos.y = @mod(self.pos.y, robot_room_bounds.y);
    }

    fn quadrant(self: Robot) Quadrant {
        const middle_x = @divFloor(robot_room_bounds.x, 2);
        const middle_y = @divFloor(robot_room_bounds.y, 2);

        if (self.pos.x < middle_x) {
            if (self.pos.y < middle_y) {
                return .top_left;
            }
            if (self.pos.y > middle_y) {
                return .top_right;
            }
            return .none;
        }
        if (self.pos.x > middle_x) {
            if (self.pos.y < middle_y) {
                return .bottom_left;
            }
            if (self.pos.y > middle_y) {
                return .bottom_right;
            }
            return .none;
        }
        return .none;
    }
};

const Quadrant = enum {
    top_left,
    top_right,
    bottom_left,
    bottom_right,
    none,
};

fn bathroomSafetyFactor(robots: []const u8, ally: std.mem.Allocator) !i32 {
    _ = ally;

    // top_left, top_right, bottom_left, bottom_right, none
    var quadrants: [5]i32 = .{0} ** 5;

    var iter = std.mem.splitScalar(u8, robots, '\n');
    while (iter.next()) |robot_str| {
        if (robot_str.len == 0) {
            break;
        }

        var robot = Robot.parse(robot_str);
        for (0..100) |_| {
            robot.updatePosition(.forward);
        }
        quadrants[@intFromEnum(robot.quadrant())] += 1;
    }

    var safety_factor: i32 = 1;
    for (0..4) |idx| {
        safety_factor *= quadrants[idx];
    }

    return safety_factor;
}

fn robotPlotter(robot_defs: []const u8, ally: std.mem.Allocator) !u32 {
    var robots = try std.ArrayList(Robot).initCapacity(ally, 100);
    defer robots.deinit();
    var robot_iter = std.mem.splitScalar(u8, robot_defs, '\n');

    while (robot_iter.next()) |robot_str| {
        if (robot_str.len == 0) {
            break;
        }
        try robots.append(Robot.parse(robot_str));
    }

    const bounds_x: usize = @intCast(robot_room_bounds.x);
    const bounds_y: usize = @intCast(robot_room_bounds.y);

    var image_data = try ally.alloc(u8, bounds_x * bounds_y);
    defer ally.free(image_data);
    @memset(image_data, 0);
    const image: [][]u8 = try ally.alloc([]u8, bounds_y);
    defer ally.free(image);
    for (image, 0..) |*row, idx| {
        row.* = image_data[idx * bounds_x .. (idx + 1) * bounds_x];
    }

    var elapsed_seconds: u32 = 0;
    // horizontal pattern starts at 50 seconds and repeats every 103
    // vertical pattern starts at 95 and repeats every 101
    while (true) {
        if (@mod(elapsed_seconds, 101) != 95) {
            elapsed_seconds += 1;
            updateRobots(&robots, .forward);
            continue;
        }

        try updateScreen(robots, image, elapsed_seconds);
        switch (try getInput()) {
            .stop => break,
            .back => {
                elapsed_seconds -= 1;
                updateRobots(&robots, .reverse);
            },
            .cont => {
                elapsed_seconds += 1;
                updateRobots(&robots, .forward);
            },
        }
    }
    return elapsed_seconds;
}

fn updateRobots(robots: *std.ArrayList(Robot), dir: Dir) void {
    for (robots.items) |*robot| {
        robot.updatePosition(dir);
    }
}

fn updateScreen(robots: std.ArrayList(Robot), image: [][]u8, seconds: u32) !void {
    const clear_terminal = "\x1B[2J\x1B[H";

    const stdout = std.io.getStdOut().writer();
    for (image) |row| {
        @memset(row, 0);
    }

    for (robots.items) |robot| {
        image[@intCast(robot.pos.y)][@intCast(robot.pos.x)] += 1;
    }

    _ = try stdout.write(clear_terminal);
    try stdout.print("seconds passed: {d}\n", .{seconds});
    for (image) |row| {
        for (row) |count| {
            const count_ch = if (count >= 10)
                'x'
            else if (count == 0)
                '.'
            else
                count + '0';

            try stdout.print("{c} ", .{count_ch});
        }
        try stdout.writeByte('\n');
    }
}

const Action = enum { stop, back, cont };
fn getInput() !Action {
    var read_buf: [64]u8 = .{0} ** 64;
    const stdin = std.io.getStdIn().reader();
    _ = try stdin.read(read_buf[0..]);

    return switch (read_buf[0]) {
        's' => .stop,
        'b' => .back,
        else => .cont,
    };
}
