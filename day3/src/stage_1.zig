const std = @import("std");
const Input = @import("./input.zig").Input;

const Allocator = std.mem.Allocator;

pub const Stage1 = struct {
    allocator: Allocator,

    pub fn init(allocator: Allocator, input: *Input) !Stage1 {
        _ = input;
        return Stage1{
            .allocator = allocator,
        };
    }

    pub fn answer(self: Stage1) usize {
        _ = self;
        return 0;
    }

    pub fn deinit(self: Stage1) void {
        _ = self;
    }
};

test "empty" {
    const input = Input.fromOwnedSlice(
        &[_]Round{
            Round{Shape.rock, Shape.paper},
            Round{Shape.paper, Shape.rock},
            Round{Shape.scissors, Shape.scissors},
        },
    );
}