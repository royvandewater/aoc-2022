const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Input = struct {
    pub fn parse(allocator: Allocator, reader: anytype) !Input {
        _ = allocator;
        _ = reader;

        return Input{};
    }

    pub fn deinit(self: Input) void {
        _ = self;
    }
};
