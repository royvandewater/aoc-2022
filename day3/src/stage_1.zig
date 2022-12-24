const std = @import("std");
const Input = @import("./input.zig").Input;
const Rucksack = @import("./input.zig").Rucksack;

const Allocator = std.mem.Allocator;


pub const Stage1 = struct {
    allocator: Allocator,
    rucksacks: []Rucksack,

    pub fn init(allocator: Allocator, input: *Input) !Stage1 {
        const i = try Input.fromSlice(allocator, input.rucksacks);

        return Stage1{
            .allocator = allocator,
            .rucksacks = i.rucksacks,
        };
    }

    pub fn answer(self: Stage1) usize {
        var total: usize = 0;

        std.debug.print("\n", .{});
        for (self.rucksacks) |rucksack| {
            const duplicate = findDuplicateLetter(rucksack);
            total += valueOf(duplicate);
        }

        return total;
    }

    pub fn deinit(self: Stage1) void {
        for (self.rucksacks) |rucksack| {
            self.allocator.free(rucksack[0]);
            self.allocator.free(rucksack[1]);
        }

        self.allocator.free(self.rucksacks);
    }
};

fn findDuplicateLetter(rucksack: Rucksack) u8 {
    const first = rucksack[0];
    const second = rucksack[1];

    for (first) |rune| {
        const res = std.mem.indexOf(u8, second, &[_]u8{rune});
        if (res != null) {
            return rune;
        }
    }

    return 0;
}

fn valueOf(n: u8) usize {
    if (n >= 97) {
        return n - 96;
    }
    return n - 38;
}

const test_allocator = std.testing.allocator;
const expectEqual = std.testing.expectEqual;

test "empty" {
    var input = try Input.fromString(test_allocator, "");
    defer input.deinit();

    var stage_1 = try Stage1.init(test_allocator, &input);
    defer stage_1.deinit();

    try expectEqual(@as(usize, 0), stage_1.answer());
}

test "example 1" {
    var input = try Input.fromString(test_allocator,
        \\vJrwpWtwJgWrhcsFMMfFFhFp
        \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
        \\PmmdzqPrVvPwwTWBwg
        \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
        \\ttgJtRGJQctTZtZT
        \\CrZsJsPPZsGzwwsLwLmpwMDw
    );
    defer input.deinit();

    var stage_1 = try Stage1.init(test_allocator, &input);
    defer stage_1.deinit();

    try expectEqual(@as(usize, 157), stage_1.answer());
}