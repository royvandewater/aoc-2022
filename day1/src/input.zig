const std = @import("std");

const Elf = []usize;

pub const Input = struct {
    allocator: std.mem.Allocator,
    elves: []Elf,

    pub fn fromOwnedSlice(allocator: std.mem.Allocator, slice: []Elf) !Input {
        var elves = std.ArrayList(Elf).init(allocator);

        for (slice) |chunk| {
            var elf = try allocator.alloc(usize, chunk.len);
            std.mem.copy(usize, elf, chunk);
            try elves.append(elf);
        }

        return Input {
            .allocator = allocator,
            .elves = elves.toOwnedSlice(),
        };
    }

    pub fn parse(allocator: std.mem.Allocator, reader: anytype) !Input {
        var input_str = try reader.readAllAlloc(allocator, 1024 * 1024);
        defer allocator.free(input_str);

        var elf_strs = std.mem.split(u8, input_str, "\n\n");
        var elves = std.ArrayList(Elf).init(allocator);

        while (elf_strs.next()) |elf_str| {
            if (elf_str.len == 0) { continue; }

            var elf = try parse_elf(allocator, elf_str);
            try elves.append(elf);
        }

        return Input{
            .allocator = allocator,
            .elves = elves.toOwnedSlice(),
        };
    }

    pub fn len(self: Input) usize {
        return self.elves.len;
    }

    pub fn deinit(self: Input) void {
        for (self.elves) |elf| {
            self.allocator.free(elf);
        }

        self.allocator.free(self.elves);
    }
};

fn parse_elf(allocator: std.mem.Allocator, elf_str: []const u8) !Elf {
    var elf = std.ArrayList(usize).init(allocator);
    var lines = std.mem.split(u8, elf_str, "\n");

    while (lines.next()) |line| {
        try elf.append(try std.fmt.parseUnsigned(usize, line, 10));
    }

    return elf.toOwnedSlice();
}


const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

test "parse empty" {
    var br = std.io.fixedBufferStream("");
    var input = try Input.parse(test_allocator, br.reader());
    defer input.deinit();

    try expect(0 == input.len());
}

test "parse one elf" {
    var br = std.io.fixedBufferStream(
        \\1000
        \\2000
    );
    var input = try Input.parse(test_allocator, br.reader());
    defer input.deinit();

    try expect(1 == input.len());

    const elf = input.elves[0];
    try expect(std.mem.eql(usize, elf, &[_]usize{1000, 2000}));
}

test "parse two elves" {
    var br = std.io.fixedBufferStream(
        \\3000
        \\1000
        \\
        \\4000
    );
    var input = try Input.parse(test_allocator, br.reader());
    defer input.deinit();

    try expect(2 == input.len());

    const elf_1 = input.elves[0];
    try expect(std.mem.eql(usize, elf_1, &[_]usize{3000, 1000}));

    const elf_2 = input.elves[1];
    try expect(std.mem.eql(usize, elf_2, &[_]usize{4000}));
}

test "using fromOwnedSlice empty" {
    var input = try Input.fromOwnedSlice(test_allocator, &[_]Elf{});
    defer input.deinit();

    try expect(0 == input.len());
}

test "using fromOwnedSlice 1 elf" {
    var input_elf = [_]usize{1};

    var input = try Input.fromOwnedSlice(test_allocator, &[_]Elf{
        &input_elf,
    });
    defer input.deinit();

    try expect(1 == input.len());

    const elf = input.elves[0];
    try expect(std.mem.eql(usize, elf, &input_elf));
}

test "using fromOwnedSlice 2 elves" {
    var input_elf_1 = [_]usize{1};
    var input_elf_2 = [_]usize{2, 3};

    var input = try Input.fromOwnedSlice(test_allocator, &[_]Elf{
        &input_elf_1,
        &input_elf_2,
    });
    defer input.deinit();

    try expect(2 == input.len());

    const elf_1 = input.elves[0];
    try expect(std.mem.eql(usize, elf_1, &input_elf_1));

    const elf_2 = input.elves[1];
    try expect(std.mem.eql(usize, elf_2, &input_elf_2));
}
