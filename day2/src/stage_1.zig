const std = @import("std");
const Input = @import("./input.zig").Input;
const Round = @import("./input.zig").Round;
const Shape = @import("./input.zig").Shape;

const Allocator = std.mem.Allocator;

pub const Stage1 = struct {
    allocator: Allocator,
    rounds: []Round,

    pub fn init(allocator: Allocator, input: *Input) !Stage1 {
        var rounds = try allocator.alloc(Round, input.rounds.len);

        std.mem.copy(Round, rounds, input.rounds);

        return Stage1{
            .allocator = allocator,
            .rounds = rounds,
        };
    }

    pub fn answer(self: Stage1) usize {
        var total: usize = 0;

        for (self.rounds) |round| total += scoreRound(round);

        return total;
    }

    pub fn deinit(self: Stage1) void {
        self.allocator.free(self.rounds);
    }

};

fn scoreRound(round: Round) usize {
    const theirs = round[0];
    const ours = round[1];

    return switch (theirs) {
        Shape.rock => switch (ours) {
            Shape.rock => 3 + 1,
            Shape.paper => 6 + 2,
            Shape.scissors => 0 + 3,
        },
        Shape.paper => switch (ours) {
            Shape.rock => 0 + 1,
            Shape.paper => 3 + 2,
            Shape.scissors => 6 + 3,
        },
        Shape.scissors => switch (ours) {
            Shape.rock => 6 + 1,
            Shape.paper => 0 + 2,
            Shape.scissors => 3 + 3,
        },
    };
}

const test_allocator = std.testing.allocator;
const expectEqual = std.testing.expectEqual;
test "empty" {
    var input = try Input.fromSlice(test_allocator, &[_]Round{});
    defer input.deinit();

    var stage_1 = try Stage1.init(test_allocator, &input);
    defer stage_1.deinit();

    try expectEqual(@as(usize, 0), stage_1.answer());
}

test "example 1" {
    var rounds = [_]Round{
        Round{Shape.rock, Shape.paper},
        Round{Shape.paper, Shape.rock},
        Round{Shape.scissors, Shape.scissors},
    };
    var input = try Input.fromSlice(test_allocator, &rounds);
    defer input.deinit();

    var stage_1 = try Stage1.init(test_allocator, &input);
    defer stage_1.deinit();

    try expectEqual(@as(usize, 15), stage_1.answer());
}
