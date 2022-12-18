const std = @import("std");

const Input = struct {
    pub fn len(self: Input) u8 {
        _ = self;
        return 0;
    }
};

// pub fn parseInput(comptime Reader: type) !void {
pub fn parseInput(reader: anytype) Input {
    _ = reader;
    return Input{};
}
