const std = @import("std");
const Input = @import("./input.zig").Input;

const Elf = struct {
    items: std.ArrayList(usize),

    pub fn init(items: *std.ArrayList(usize)) !Elf {
        return Elf {
            .items = try items.clone(),
        };
    }

    pub fn deinit(self: *Elf) void {
        self.items.deinit();
    }

    pub fn sum(self: *Elf) usize {
        var total: usize = 0;

        for (self.items.items) |item| {
            total += item;
        }

        return total;
    }
};

pub const Stage1 = struct {
    elves: std.ArrayList(Elf),

    pub fn init(allocator: std.mem.Allocator, input: *Input) !Stage1 {
        var elves = try std.ArrayList(Elf).initCapacity(allocator, input.len());

        while (true) {
            var res = input.next();
            if (res == null) {
                break;
            }

            var elf_data = res.?;
            var elf = try Elf.init(&elf_data);
            try elves.append(elf);
        }

        return Stage1{.elves = elves};
    }

    pub fn answer(self: *Stage1) usize {
        var max: usize = 0;

        while (true) {
            var res = self.elves.popOrNull();
            if (res == null) {
                break;
            }
            var elf = res.?;

            var sum = elf.sum();
            if (sum > max) {
                max = sum;
            }
        }

        return max;
    }

    pub fn deinit(self: *Stage1) void {
        while (true) {
            var res = self.elves.popOrNull();
            if (res == null) {
                break;
            }

            var elf = res.?;
            elf.deinit();
        }

        self.elves.deinit();
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
    var input = try Input.parseInput(test_allocator, br.reader());
    var stage_1 = try Stage1.init(test_allocator, &input);
    defer stage_1.deinit();

    try std.testing.expect(24000 == stage_1.answer());
}