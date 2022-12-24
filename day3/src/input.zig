const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Rucksack = [2][]const u8;

pub const Input = struct {
    allocator: Allocator,
    rucksacks: []Rucksack,

    pub fn fromSlice(allocator: Allocator, slice: []Rucksack) !Input {
        var rucksacks = try allocator.alloc(Rucksack, slice.len);

        for (slice) |rucksack, i| {
            rucksacks[i] = Rucksack{
                try copy(allocator, rucksack[0]),
                try copy(allocator, rucksack[1]),
            };
        }

        return Input{
            .allocator = allocator,
            .rucksacks = rucksacks,
        };
    }

    pub fn fromString(allocator: Allocator, str: []const u8) !Input {
        var rucksacks = std.ArrayList(Rucksack).init(allocator);

        var lines = std.mem.split(u8, str, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) continue;

            const n = line.len / 2;
            try rucksacks.append(Rucksack{
                try copy(allocator, line[0..n]),
                try copy(allocator, line[n..]),
            });
        }

        return Input{
            .allocator = allocator,
            .rucksacks = rucksacks.toOwnedSlice(),
        };
    }

    pub fn fromReader(allocator: Allocator, reader: anytype) !Input {
        var rucksacks = std.ArrayList(Rucksack).init(allocator);

        var buf: [128]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            const n = line.len / 2;
            try rucksacks.append(Rucksack{
                try copy(allocator, line[0..n]),
                try copy(allocator, line[n..]),
            });
        }

        return Input{
            .allocator = allocator,
            .rucksacks = rucksacks.toOwnedSlice(),
        };
    }

    pub fn deinit(self: Input) void {
        for (self.rucksacks) |rucksack| {
            self.allocator.free(rucksack[0]);
            self.allocator.free(rucksack[1]);
        }

        self.allocator.free(self.rucksacks);
    }
};

fn copy(allocator: Allocator, str: []const u8) ![]const u8 {
    var buf = try allocator.alloc(u8, str.len);
    std.mem.copy(u8, buf, str);
    return buf;
}

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

test "fromSlice empty" {
    var rucksacks = [_]Rucksack{};
    var input = try Input.fromSlice(test_allocator, &rucksacks);
    defer input.deinit();

    try expectEqual(@as(usize, 0), input.rucksacks.len);
}

test "fromSlice one rucksack" {
    var rucksacks = [_]Rucksack{Rucksack{"abc","123"}};
    var input = try Input.fromSlice(test_allocator, &rucksacks);
    defer input.deinit();

    try expectEqual(@as(usize, 1), input.rucksacks.len);
    try expectEqualStrings("abc", input.rucksacks[0][0]);
    try expectEqualStrings("123", input.rucksacks[0][1]);
}


test "fromString empty" {
    var input = try Input.fromString(test_allocator, "");
    defer input.deinit();

    try expectEqual(@as(usize, 0), input.rucksacks.len);
}

test "fromString one rucksack" {
    var input = try Input.fromString(test_allocator, "abc123");
    defer input.deinit();

    try expectEqual(@as(usize, 1), input.rucksacks.len);
    try expectEqualStrings("abc", input.rucksacks[0][0]);
    try expectEqualStrings("123", input.rucksacks[0][1]);
}
