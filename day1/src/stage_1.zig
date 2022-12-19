const std = @import("std");
const Input = @import("./input.zig").Input;
const Elf = @import("./elf.zig").Elf;

pub const Stage1 = struct {
    allocator: std.mem.Allocator,
    elves: []Elf,

    pub fn init(allocator: std.mem.Allocator, input: *Input) !Stage1 {
        var elves = try allocator.alloc(Elf, input.elves.len);

        for (input.elves) |elf_data, i| {
            elves[i] = try Elf.init(allocator, elf_data);
        }

        return Stage1{
            .allocator = allocator,
            .elves = elves,
        };
    }

    pub fn answer(self: Stage1) usize {
        var max: usize = 0;

        for (self.elves) |elf| {
            if (elf.sum() > max) {
                max = elf.sum();
            }
        }

        return max;
    }

    pub fn deinit(self: Stage1) void {
        for (self.elves) |elf| elf.deinit();

        self.allocator.free(self.elves);
    }
};


const test_allocator = std.testing.allocator;

test "example 1" {
    var br = std.io.fixedBufferStream(
        \\1000
        \\2000
        \\3000
        \\
        \\4000
        \\
        \\5000
        \\6000
        \\
        \\7000
        \\8000
        \\9000
        \\
        \\10000
    );
    var input = try Input.parse(test_allocator, br.reader());
    defer input.deinit();
    var stage_1 = try Stage1.init(test_allocator, &input);
    defer stage_1.deinit();

    try std.testing.expect(24000 == stage_1.answer());
}