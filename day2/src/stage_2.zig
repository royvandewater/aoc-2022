const std = @import("std");
const Input = @import("./input.zig").Input;
const Round = @import("./input.zig").Round;
const Shape = @import("./input.zig").Shape;

const Allocator = std.mem.Allocator;

const Outcome = enum{loss, draw, win};

pub const Stage2 = struct {
    allocator: Allocator,
    rounds: []Round,

    pub fn init(allocator: Allocator, input: *Input) !Stage2 {
        var rounds = try allocator.alloc(Round, input.rounds.len);

        std.mem.copy(Round, rounds, input.rounds);

        return Stage2{
            .allocator = allocator,
            .rounds = rounds,
        };
    }

    pub fn answer(self: Stage2) usize {
        var total: usize = 0;

        for (self.rounds) |round| total += scoreRound(round);

        return total;
    }

    pub fn deinit(self: Stage2) void {
        self.allocator.free(self.rounds);
    }

};

fn scoreRound(round: Round) usize {
    const theirs = round[0];
    const ours = shapeToOutcome(round[1]);

    return switch (theirs) {
        Shape.rock => switch (ours) {
            Outcome.loss => 0 + 3,
            Outcome.draw => 3 + 1,
            Outcome.win => 6 + 2,
        },
        Shape.paper => switch (ours) {
            Outcome.loss => 0 + 1,
            Outcome.draw => 3 + 2,
            Outcome.win => 6 + 3,
        },
        Shape.scissors => switch (ours) {
            Outcome.loss => 0 + 2,
            Outcome.draw => 3 + 3,
            Outcome.win => 6 + 1,
        },
    };
}

fn shapeToOutcome(shape: Shape) Outcome {
    return switch (shape) {
        Shape.rock => Outcome.loss,
        Shape.paper => Outcome.draw,
        Shape.scissors => Outcome.win,
    };
}

const test_allocator = std.testing.allocator;
const expectEqual = std.testing.expectEqual;
test "empty" {
    var input = try Input.fromSlice(test_allocator, &[_]Round{});
    defer input.deinit();

    var stage_2 = try Stage2.init(test_allocator, &input);
    defer stage_2.deinit();

    try expectEqual(@as(usize, 0), stage_2.answer());
}

test "example 1" {
    var rounds = [_]Round{
        Round{Shape.rock, Shape.paper},
        Round{Shape.paper, Shape.rock},
        Round{Shape.scissors, Shape.scissors},
    };
    var input = try Input.fromSlice(test_allocator, &rounds);
    defer input.deinit();

    var stage_2 = try Stage2.init(test_allocator, &input);
    defer stage_2.deinit();

    try expectEqual(@as(usize, 12), stage_2.answer());
}
