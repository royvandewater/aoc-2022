const std = @import("std");

const Elf = std.ArrayList(usize);

const Input = struct {
    allocator: std.mem.Allocator,
    elves: std.ArrayList(Elf),

    pub fn len(self: Input) usize {
        return self.elves.items.len;
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
        .elves = elves,
    };
}

const test_allocator = std.testing.allocator;
test "parse one elf" {
    var br = std.io.fixedBufferStream(
        \\1000
        \\2000
    );
    const input = try parseInput(test_allocator, br.reader());
    defer input.deinit();

    std.debug.assert(1 == input.len());
}
