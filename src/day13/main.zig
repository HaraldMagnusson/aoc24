const std = @import("std");
const extras = @import("extras");

test "first example" {
    const ally = std.testing.allocator;
    const test_path = "src/day13/test1.in";

    try extras.runAocTest(test_path, u32, totalTokenCost, ally);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const ally = gpa.allocator();

    const puzzle_input = try extras.readFileFromCmdArg(ally);
    defer ally.free(puzzle_input);

    std.debug.print(
        "Total tokens required to win all possible prizes:\n{d}\n",
        .{totalTokenCost(puzzle_input, ally) catch unreachable},
    );
}

fn totalTokenCost(definition: []const u8, ally: std.mem.Allocator) !u32 {
    _ = ally;

    var machine_iter = std.mem.splitSequence(u8, definition, "\n\n");

    var total_cost: u32 = 0;

    while (machine_iter.next()) |def| {
        const machine_def = MachineDef.parse(def);
        total_cost += machine_def.tokensRequiredForSolution() orelse 0;
    }

    return total_cost;
}

const MachineDef = struct {
    a: @Vector(2, i64),
    b: @Vector(2, i64),
    price: @Vector(2, i64),

    fn parse(def: []const u8) MachineDef {
        // format example:
        // Button A: X+94, Y+34
        // Button B: X+22, Y+67
        // Prize: X=8400, Y=5400

        var iter = std.mem.splitAny(u8, def, "+,=\n");
        var a: @Vector(2, i64) = undefined;
        var b: @Vector(2, i64) = undefined;
        var price: @Vector(2, i64) = undefined;

        const base10 = 10;
        _ = iter.first(); // "Button A: X"
        a[0] = std.fmt.parseUnsigned(i64, iter.next().?, base10) catch unreachable;
        _ = iter.next(); // " Y"
        a[1] = std.fmt.parseUnsigned(i64, iter.next().?, base10) catch unreachable;

        _ = iter.next(); // "Button B: X"
        b[0] = std.fmt.parseUnsigned(i64, iter.next().?, base10) catch unreachable;
        _ = iter.next(); // " Y"
        b[1] = std.fmt.parseUnsigned(i64, iter.next().?, base10) catch unreachable;

        _ = iter.next(); // "Price: X"
        price[0] = std.fmt.parseUnsigned(u32, iter.next().?, base10) catch unreachable;
        _ = iter.next(); // " Y"
        price[1] = std.fmt.parseUnsigned(u32, iter.next().?, base10) catch unreachable;

        return MachineDef{ .a = a, .b = b, .price = price };
    }

    // returns null if no solution is possible
    fn tokensRequiredForSolution(self: MachineDef) ?u32 {
        // simple math solution
        // https://www.desmos.com/calculator/bqmjdsuqx0

        const numerator: i64 = self.b[1] * self.price[0] - self.b[0] * self.price[1];
        const denominator: i64 = self.b[1] * self.a[0] - self.b[0] * self.a[1];

        // denom == 0 => A and B cause parallel movement of the claw
        // can A or B be a solution?
        if (denominator == 0) {
            const a_count: ?u32 = if (@reduce(
                .And,
                @mod(self.price, self.a) == @Vector(2, i64){ 0, 0 },
            ))
                @intCast(@divExact(self.price[0], self.a[0]))
            else
                null;

            const b_count: ?u32 = if (@reduce(
                .And,
                @mod(self.price, self.b) == @Vector(2, i64){ 0, 0 },
            ))
                @intCast(@divExact(self.price[0], self.b[0]))
            else
                null;

            if (a_count == null and b_count == null) {
                return null; // no solution
            }

            // return cheapest
            const more_than_max_count = 4711;
            return @min(3 * (a_count orelse more_than_max_count), b_count orelse more_than_max_count);
        }

        // amount of times to mash A cannot be negative
        if (std.math.sign(numerator) != std.math.sign(denominator)) {
            return null;
        }

        const a_count: u32 = @intCast(std.math.divExact(i64, numerator, denominator) catch return null);
        const b_count: u32 = @intCast(std.math.divExact(
            i64,
            self.price[1] - self.a[1] * a_count,
            self.b[1],
        ) catch return null);

        const cost: u32 = 3 * @as(u32, @intCast(a_count)) + @as(u32, @intCast(b_count));
        return cost;
    }
};
