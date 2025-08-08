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

    std.debug.print(
        "Bathroom safety factor: {d}\n",
        .{bathroomSafetyFactor(puzzle_input, ally) catch unreachable},
    );
}

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

    fn updatePosition(self: *Robot) void {
        self.pos.x += self.vel.x;
        self.pos.y += self.vel.y;
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
        // std.debug.print("robot: {any}\n", .{robot});
        for (0..100) |_| {
            robot.updatePosition();
        }
        quadrants[@intFromEnum(robot.quadrant())] += 1;
    }

    var safety_factor: i32 = 1;
    for (0..4) |idx| {
        safety_factor *= quadrants[idx];
    }

    return safety_factor;
}
