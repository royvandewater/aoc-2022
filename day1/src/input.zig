const std = @import("std");

const Elf = std.ArrayList(usize);

const Input = struct {
    allocator: std.mem.Allocator,
    elves: std.ArrayList(Elf),

    pub fn len(self: Input) usize {
        return self.elves.items.len;
    }

    pub fn next(self: *Input) ?Elf {
        return self.elves.popOrNull();
    }

    pub fn deinit(self: Input) void {
        for (self.elves.items) |elf| {
            elf.deinit();
        }

        self.elves.deinit();
    }
};

// pub fn parseInput(comptime Reader: type) !void {
pub fn parseInput(allocator: std.mem.Allocator, reader: anytype) !Input {
    var elves = std.ArrayList(Elf).init(allocator);

    var elf = std.ArrayList(usize).init(allocator);
    var buf: [100]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            try elves.append(elf);
            elf = std.ArrayList(usize).init(allocator);
            continue;
        }

        const value = try std.fmt.parseUnsigned(usize, line, 10);
        try elf.append(value);
    }
    try elves.append(elf);

    return Input{
        .allocator = allocator,
        .elves = try reverseList(Elf, &elves),
    };
}

fn reverseList(comptime T: type, list: *std.ArrayList(T)) !std.ArrayList(T) {
    var new_list = try std.ArrayList(T).initCapacity(list.allocator, list.items.len);

    while (list.popOrNull()) |item| {
        try new_list.append(item);
    }

    defer list.deinit();
    return new_list;
}

const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

test "parse one elf" {
    var br = std.io.fixedBufferStream(
        \\1000
        \\2000
    );
    var input = try parseInput(test_allocator, br.reader());
    defer input.deinit();

    try expect(1 == input.len());

    const elf = input.next().?;
    defer elf.deinit();
    try expect(std.mem.eql(usize, elf.items, &[_]usize{1000, 2000}));

}

test "parse two elves" {
    var br = std.io.fixedBufferStream(
        \\3000
        \\1000
        \\
        \\4000
    );
    var input = try parseInput(test_allocator, br.reader());
    defer input.deinit();

    try expect(2 == input.len());

    const elf_1 = input.next().?;
    defer elf_1.deinit();
    try expect(std.mem.eql(usize, elf_1.items, &[_]usize{3000, 1000}));

    const elf_2 = input.next().?;
    defer elf_2.deinit();
    try expect(std.mem.eql(usize, elf_2.items, &[_]usize{4000}));

    try expect(null == input.next());

}
