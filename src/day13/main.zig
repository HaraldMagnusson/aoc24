const std = @import("std");
const extras = @import("extras");

test "first example" {
    const ally = std.testing.allocator;
    const test_path = "src/day13/test1.in";

    try extras.runAocTest(test_path, i64, totalTokenCost, ally);
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

fn totalTokenCost(definition: []const u8, ally: std.mem.Allocator) !i64 {
    _ = ally;

    var machine_iter = std.mem.splitSequence(u8, definition, "\n\n");

    var total_cost: i64 = 0;

    while (machine_iter.next()) |def| {
        const machine = Machine.parse(def);
        total_cost += machine.tokensRequiredForSolution() orelse 0;
    }

    return total_cost;
}

const Machine = struct {
    a: @Vector(2, i64),
    b: @Vector(2, i64),
    price: @Vector(2, i64),

    fn parse(def: []const u8) Machine {
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
        price[0] = std.fmt.parseUnsigned(i64, iter.next().?, base10) catch unreachable;
        _ = iter.next(); // " Y"
        price[1] = std.fmt.parseUnsigned(i64, iter.next().?, base10) catch unreachable;

        const correction: @Vector(2, i64) = @splat(10000000000000);
        return Machine{ .a = a, .b = b, .price = price + correction };
    }

    // returns null if no solution is possible
    fn tokensRequiredForSolution(self: Machine) ?i64 {
        // linear system of equations: [a b]x = price

        const determinant = self.a[0] * self.b[1] - self.a[1] * self.b[0];
        if (determinant == 0) {
            // no unique solution, A and B cause parallel movement
            return null;
        }

        // Cramers rule
        const determinant_a = self.price[0] * self.b[1] - self.price[1] * self.b[0];
        if (@mod(determinant_a, determinant) != 0) {
            return null;
        }
        const a_count = @divExact(determinant_a, determinant);

        const determinant_b = self.a[0] * self.price[1] - self.a[1] * self.price[0];
        if (@mod(determinant_b, determinant) != 0) {
            return null;
        }
        const b_count = @divExact(determinant_b, determinant);

        return 3 * a_count + b_count;
    }
};
