const std = @import("std");
const Input = @import("./input.zig").Input;
const Instruction = @import("./input.zig").Instruction;

const Allocator = std.mem.Allocator;
const Stack = std.ArrayList(u8);
const Stacks = std.AutoHashMap(usize, Stack);

pub const Stage2 = struct {
    allocator: Allocator,
    stacks: Stacks,
    instructions: []Instruction,

    pub fn deinit(self: *Stage2) void {
        freeStacks(&self.stacks);
        self.allocator.free(self.instructions);
    }

    pub fn fromInput(allocator: Allocator, input: *Input) !Stage2 {
        var instructions = try allocator.alloc(Instruction, input.instructions.len);
        std.mem.copy(Instruction, instructions, input.instructions);

        return Stage2{
            .allocator = allocator,
            .stacks = try copyStacks(allocator, input.stacks),
            .instructions = instructions,
        };
    }

    pub fn answer(self: *Stage2) ![]const u8 {
        var stacks: Stacks = try copyStacks(self.allocator, self.stacks);
        defer freeStacks(&stacks);

        for (self.instructions) |instruction| try applyInstruction(self.allocator, &stacks, instruction);

        var max_stack_i: usize = 0;
        var stacks_i_iterator = stacks.keyIterator();
        while (stacks_i_iterator.next()) |i| {
            if (i.* > max_stack_i) max_stack_i = i.*;
        }

        var total = try self.allocator.alloc(u8, stacks.count());

        var stacks_iterator = stacks.iterator();
        while (stacks_iterator.next()) |entry| {
            var i = entry.key_ptr.* - 1;
            var stack = entry.value_ptr.*;

            total[i] = stack.pop();
        }

        return total;
    }
};

fn applyInstruction(allocator: Allocator, stacks: *Stacks, instruction: Instruction) !void {
    var crates = try std.ArrayList(u8).initCapacity(allocator, instruction.quantity);
    defer crates.deinit();

    var source = stacks.getPtr(instruction.from).?;
    for (times(instruction.quantity)) |_| {
        try crates.append(source.pop());
    }

    var destination = stacks.getPtr(instruction.to).?;
    while (crates.popOrNull()) |crate| {
        try destination.append(crate);
    }
}

fn times(len: usize) []const u0 {
    return @as([*]u0, undefined)[0..len];
}

fn copyStacks(allocator: Allocator, in_stacks: Stacks) !Stacks {
    var out_stacks = Stacks.init(allocator);

    var stacks_iterator = in_stacks.keyIterator();
    while (stacks_iterator.next()) |i| {
        var in_stack = in_stacks.get(i.*).?;
        try out_stacks.put(i.*, try in_stack.clone());
    }

    return out_stacks;
}

fn freeStacks(stacks: *Stacks) void {
    var stacks_iter = stacks.valueIterator();
    while (stacks_iter.next()) |stack| {
        stack.deinit();
    }
    stacks.deinit();
}

const test_allocator = std.testing.allocator;
const expectEqualStrings = std.testing.expectEqualStrings;

test "empty" {
    var input = try Input.fromString(test_allocator, "");
    defer input.deinit();

    var stage_2 = try Stage2.fromInput(test_allocator, &input);
    defer stage_2.deinit();

    var answer = try stage_2.answer();
    defer test_allocator.free(answer);

    try expectEqualStrings("", answer);
}

test "example 1" {
    var input = try Input.fromString(test_allocator,
        \\    [D]
        \\[N] [C]
        \\[Z] [M] [P]
        \\ 1   2   3
        \\
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
    );
    defer input.deinit();

    var stage_2 = try Stage2.fromInput(test_allocator, &input);
    defer stage_2.deinit();

    var answer = try stage_2.answer();
    defer test_allocator.free(answer);

    try expectEqualStrings("MCD", answer);
}
