const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Shape = enum{ rock, paper, scissors };
pub const Round = [2]Shape;

pub const Input = struct {
    allocator: Allocator,
    rounds: []Round,

    pub fn fromSlice(allocator: Allocator, slice: []Round) !Input {
        var rounds = try allocator.alloc(Round, slice.len);

        for (slice) |round, i| rounds[i] = round;

        return Input{
            .allocator = allocator,
            .rounds = rounds,
        };
    }

    pub fn fromString(allocator: Allocator, str: []const u8) !Input {
        var rounds = std.ArrayList(Round).init(allocator);

        var lines = std.mem.split(u8, str, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) continue;

            const shape_1 = try charToShape(line[0]);
            const shape_2 = try charToShape(line[2]);

            try rounds.append([2]Shape{shape_1, shape_2});
        }

        return Input{
            .allocator = allocator,
            .rounds = rounds.toOwnedSlice(),
        };
    }

    pub fn parse(allocator: Allocator, reader: anytype) !Input {
        var rounds = std.ArrayList(Round).init(allocator);
        var buf: [128]u8 = undefined;
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
test "parse empty" {
    var br = std.io.fixedBufferStream("");
    var input = try Input.parse(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 0), input.rounds.len);
}

test "parse example 1" {
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

test "fromSlice empty" {
    var input = try Input.fromSlice(test_allocator, &[_]Round{});
    defer input.deinit();

    try expectEqual(@as(usize, 0), input.rounds.len);
}

test "fromSlice example 1" {
    var rounds = [_]Round{
        Round{Shape.rock, Shape.paper},
        Round{Shape.paper, Shape.rock},
        Round{Shape.scissors, Shape.scissors},
    };
    var input = try Input.fromSlice(test_allocator, &rounds);
    defer input.deinit();

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

test "fromString empty" {
    var input = try Input.fromString(test_allocator, "");
    defer input.deinit();

    try expectEqual(@as(usize, 0), input.rounds.len);
}

test "fromString example 1" {
    var input = try Input.fromString(test_allocator,
        \\A Y
        \\B X
        \\C Z
    );
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