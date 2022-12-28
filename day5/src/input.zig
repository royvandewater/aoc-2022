const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Instruction = struct {
    quantity: usize,
    from: usize,
    to: usize,

    pub fn fromString(str: []const u8) !Instruction {
        var parts = std.mem.split(u8, str, " ");
        _ = parts.next(); // "move"
        const quantity = try std.fmt.parseUnsigned(usize, parts.next().?, 10);
        _ = parts.next(); // "from"
        const from = try std.fmt.parseUnsigned(usize, parts.next().?, 10);
        _ = parts.next(); // "to"
        const to = try std.fmt.parseUnsigned(usize, parts.next().?, 10);

        return Instruction{
            .quantity = quantity,
            .from = from,
            .to = to,
        };
    }
};

pub const Input = struct {
    allocator: Allocator,
    stacks: std.AutoHashMap(usize, std.ArrayList(u8)),
    instructions: []Instruction,

    pub fn deinit(self: *Input) void {
        var stacks = self.stacks.valueIterator();
        while (stacks.next()) |stack| {
            stack.deinit();
        }
        self.stacks.deinit();

        self.allocator.free(self.instructions);
    }

    pub fn fromReader(allocator: Allocator, reader: anytype) !Input {
        var stacks = std.AutoHashMap(usize, std.ArrayList(u8)).init(allocator);
        var instructions = std.ArrayList(Instruction).init(allocator);

        var buf: [128]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // if (line.len == 0) break;
            if (std.mem.indexOf(u8, line, "1") != null) {
                break;
            }

            for (line) |char, i| {
                if (char < 'A' or 'Z' < char) continue;
                const x = (i / 4) + 1;

                if (!stacks.contains(x)) {
                    try stacks.put(x, std.ArrayList(u8).init(allocator));
                }
                try stacks.getPtr(x).?.append(char);
            }
        }

        var stacks_iter = stacks.iterator();
        while (stacks_iter.next()) |entry| {
            var old_stack = entry.value_ptr.*;
            var new_stack = std.ArrayList(u8).init(allocator);
            while (entry.value_ptr.*.popOrNull()) |crate| {
                try new_stack.append(crate);
            }
            entry.value_ptr.* = new_stack;
            old_stack.deinit();
        }

        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 0) continue;
            try instructions.append(try Instruction.fromString(line));
        }

        return Input{
            .allocator = allocator,
            .stacks = stacks,
            .instructions = try instructions.toOwnedSlice(),
        };
    }

    pub fn fromString(allocator: Allocator, str: []const u8) !Input {
        var br = std.io.fixedBufferStream(str);

        return Input.fromReader(allocator, br.reader());
    }
};

// fn copy(allocator: Allocator, str: []const u8) ![]const u8 {
//     var buf = try allocator.alloc(u8, str.len);
//     std.mem.copy(u8, buf, str);
//     return buf;
// }

const test_allocator = std.testing.allocator;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "fromReader empty" {
    var br = std.io.fixedBufferStream("");
    var input = try Input.fromReader(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 0), input.stacks.count());
    try expectEqual(@as(usize, 0), input.instructions.len);
}

test "fromReader one stack with one crate" {
    var br = std.io.fixedBufferStream(
        \\[A]
        \\ 1
    );
    var input = try Input.fromReader(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 1), input.stacks.count());
    try expectEqual(@as(usize, 1), input.stacks.get(1).?.items.len);
    try expectEqual(@as(u8, 'A'), input.stacks.get(1).?.items[0]);
}

test "fromReader one stack with two crates" {
    var br = std.io.fixedBufferStream(
        \\[B]
        \\[A]
        \\ 1
    );
    var input = try Input.fromReader(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 1), input.stacks.count());

    var stack = input.stacks.get(1).?;
    try expectEqual(@as(usize, 2), stack.items.len);
    try expectEqual(@as(u8, 'B'), stack.pop());
    try expectEqual(@as(u8, 'A'), stack.pop());
}

test "fromReader one stack with one instruction" {
    var br = std.io.fixedBufferStream(
        \\[A] [B]
        \\ 1   2
        \\
        \\move 1 from 2 to 3
    );
    var input = try Input.fromReader(test_allocator, br.reader());
    defer input.deinit();

    try expectEqual(@as(usize, 1), input.instructions.len);
    try expectEqual(@as(usize, 1), input.instructions[0].quantity);
    try expectEqual(@as(usize, 2), input.instructions[0].from);
    try expectEqual(@as(usize, 3), input.instructions[0].to);
}

test "fromString" {
    var input = try Input.fromString(test_allocator,
        \\[A] [B]
        \\ 1   2
        \\
        \\move 1 from 2 to 3
    );
    defer input.deinit();

    try expectEqual(@as(usize, 2), input.stacks.count());
    try expectEqual(@as(usize, 1), input.stacks.get(1).?.items.len);
    try expectEqual(@as(u8, 'A'), input.stacks.get(1).?.items[0]);
    try expectEqual(@as(usize, 1), input.stacks.get(2).?.items.len);
    try expectEqual(@as(u8, 'B'), input.stacks.get(2).?.items[0]);

    try expectEqual(@as(usize, 1), input.instructions.len);
    try expectEqual(@as(usize, 1), input.instructions[0].quantity);
    try expectEqual(@as(usize, 2), input.instructions[0].from);
    try expectEqual(@as(usize, 3), input.instructions[0].to);
}
