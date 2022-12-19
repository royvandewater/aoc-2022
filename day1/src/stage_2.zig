const std = @import("std");
const Input = @import("./input.zig").Input;
const Elf = @import("./elf.zig").Elf;

const Allocator = std.mem.Allocator;

pub const Stage2 = struct {
    allocator: std.mem.Allocator,
    elves: []Elf,

    pub fn init(allocator: Allocator, input: *Input) !Stage2 {
        var elves = try allocator.alloc(Elf, input.elves.len);

        for (input.elves) |elf_data, i| {
            elves[i] = try Elf.init(allocator, elf_data);
        }

        return Stage2{
            .allocator = allocator,
            .elves = elves,
        };
    }

    pub fn answer(self: Stage2) !usize {
        const sums = try self.sortedTotals();
        defer self.allocator.free(sums);
        const sub_sums = sums[0..3];

        var total: usize = 0;

        for (sub_sums) |sum| total += sum;

        return total;
    }

    fn sortedTotals(self: Stage2) ![]usize {
        var sums = try self.totals();

        std.sort.sort(usize, sums, {}, std.sort.desc(usize));

        return sums;
    }

    fn totals(self: Stage2) ![]usize {
        var sums = try self.allocator.alloc(usize, self.elves.len);

        for (self.elves) |elf, i| sums[i] = elf.sum();

        return sums;
    }

    pub fn deinit(self: Stage2) void {
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
    var sut = try Stage2.init(test_allocator, &input);
    defer sut.deinit();

    const answer = try sut.answer();

    try std.testing.expect(45000 == answer);
}