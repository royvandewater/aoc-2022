const std = @import("std");

const Elf = std.ArrayList(usize);

const Input = struct {
    elves: std.ArrayList(Elf),

    pub fn len(self: Input) usize {
        return self.elves.items.len;
    }
};

// pub fn parseInput(comptime Reader: type) !void {
pub fn parseInput(allocator: std.mem.Allocator, reader: anytype) Input {
    _ = reader;

    return Input{
        .elves = std.ArrayList(Elf).init(allocator),
    };
}
