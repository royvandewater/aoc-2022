const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Elf = struct {
    allocator: Allocator,
    items: []usize,

    pub fn init(allocator: Allocator, slice: []usize) !Elf {
        var items = try allocator.alloc(usize, slice.len);

        std.mem.copy(usize, items, slice);

        return Elf {
            .allocator = allocator,
            .items = items,
        };
    }

    pub fn deinit(self: Elf) void {
        self.allocator.free(self.items);
    }

    pub fn sum(self: Elf) usize {
        var total: usize = 0;

        for (self.items) |item| total += item;

        return total;
    }
};