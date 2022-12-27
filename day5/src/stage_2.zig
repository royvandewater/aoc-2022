const std = @import("std");
const Input = @import("./input.zig").Input;
const Rucksack = @import("./input.zig").Rucksack;

const Allocator = std.mem.Allocator;

const Group = [3][]const u8;

pub const Stage2 = struct {
    allocator: Allocator,
    groups: []Group,

    pub fn init(allocator: Allocator, input: *Input) !Stage2 {
        return Stage2{
            .allocator = allocator,
            .groups = try groupRucksacks(allocator, input.rucksacks),
        };
    }

    pub fn deinit(self: Stage2) void {
        for (self.groups) |group| {
            self.allocator.free(group[0]);
            self.allocator.free(group[1]);
            self.allocator.free(group[2]);
        }

        self.allocator.free(self.groups);
    }

    pub fn answer(self: Stage2) usize {
        var total: usize = 0;

        for (self.groups) |group| {
            total += valueOf(findDuplicate(group));
        }

        return total;
    }
};

fn groupRucksacks(allocator: Allocator, rucksacks: []Rucksack) ![]Group {
    var groups = try allocator.alloc(Group, rucksacks.len / 3);
    var i: usize = 0;

    while (i < rucksacks.len) : (i += 3) {
        groups[i / 3] = Group{
            try std.mem.concat(allocator, u8, &[_][]const u8{rucksacks[i][0], rucksacks[i][1]}),
            try std.mem.concat(allocator, u8, &[_][]const u8{rucksacks[i + 1][0], rucksacks[i + 1][1]}),
            try std.mem.concat(allocator, u8, &[_][]const u8{rucksacks[i + 2][0], rucksacks[i + 2][1]}),
        };
    }

    return groups;
}

fn findDuplicate(group: Group) u8 {
    const first = group[0];
    const second = group[1];
    const third = group[2];

    for (first) |rune| {
        if (null != std.mem.indexOf(u8, second, &[_]u8{rune})) {
            if (null != std.mem.indexOf(u8, third, &[_]u8{rune})) {
                return rune;
            }
        }
    }

    return 0;
}

fn copy(allocator: Allocator, str: []const u8) ![]const u8 {
    var buf = try allocator.alloc(u8, str.len);
    std.mem.copy(u8, buf, str);
    return buf;
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

    var stage_2 = try Stage2.init(test_allocator, &input);
    defer stage_2.deinit();

    try expectEqual(@as(usize, 0), stage_2.answer());
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

    var stage_2 = try Stage2.init(test_allocator, &input);
    defer stage_2.deinit();

    try expectEqual(@as(usize, 70), stage_2.answer());
}
