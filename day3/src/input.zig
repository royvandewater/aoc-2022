const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Rucksack = [2][]const u8;

pub const Input = struct {
    allocator: Allocator,
    rucksacks: []Rucksack,

    pub fn fromReader(allocator: Allocator, reader: anytype) !Input {
        var rucksacks = std.ArrayList(Rucksack).init(allocator);

        var buf: [128]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            const n = line.len / 2;

            var first = try allocator.alloc(u8, n);
            std.mem.copy(u8, first, line[0..n]);

            var second = try allocator.alloc(u8, n);
            std.mem.copy(u8, second, line[n..]);

            const rucksack = Rucksack{ first, second };

            try rucksacks.append(rucksack);
        }

        var i = Input{
            .allocator = allocator,
            .rucksacks = rucksacks.toOwnedSlice(),
        };

        return i;
    }

    pub fn deinit(self: Input) void {
        for (self.rucksacks) |rucksack| {
            self.allocator.free(rucksack[0]);
            self.allocator.free(rucksack[1]);
        }

        self.allocator.free(self.rucksacks);
    }
};

const test_allocator = std.testing.allocator;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "fromReader empty" {
    var br = std.io.fixedBufferStream("");
    var input = try Input.fromReader(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 0), input.rucksacks.len);
}

test "fromReader one rucksack" {
    var br = std.io.fixedBufferStream("abc123");
    var input = try Input.fromReader(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 1), input.rucksacks.len);
    try expectEqualStrings("abc", input.rucksacks[0][0]);
    try expectEqualStrings("123", input.rucksacks[0][1]);
}
