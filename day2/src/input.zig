const std = @import("std");

const Allocator = std.mem.Allocator;

const Shape = enum{ rock, paper, scissors };
const Round = [2]Shape;

pub const Input = struct {
    allocator: Allocator,
    rounds: []Round,

    pub fn parse(allocator: Allocator, reader: anytype) !Input {
        var rounds = std.ArrayList(Round).init(allocator);
        var buf: [4]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            const shape_1 = try charToShape(line[0]);
            const shape_2 = try charToShape(line[2]);

            try rounds.append([2]Shape{shape_1, shape_2});
        }

        return Input{
            .allocator = allocator,
            .rounds = rounds.toOwnedSlice(),
        };
    }

    pub fn deinit(self: Input) void {
        self.allocator.free(self.rounds);
    }
};

fn charToShape(char: u8) !Shape {
    return switch (char) {
        'A' => Shape.rock,
        'B' => Shape.paper,
        'C' => Shape.scissors,
        'X' => Shape.rock,
        'Y' => Shape.paper,
        'Z' => Shape.scissors,
        else => error.InvalidShapeChar,
    };
}

const test_allocator = std.testing.allocator;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
test "empty" {
    var br = std.io.fixedBufferStream("");
    var input = try Input.parse(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 0), input.rounds.len);
}

test "example 1" {
    var br = std.io.fixedBufferStream(
        \\A Y
        \\B X
        \\C Z
    );
    var input = try Input.parse(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 3), input.rounds.len);

    try expectEqualSlices(
        Round,
        &[_]Round{
            Round{Shape.rock, Shape.paper},
            Round{Shape.paper, Shape.rock},
            Round{Shape.scissors, Shape.scissors},
        },
        input.rounds,
    );
}