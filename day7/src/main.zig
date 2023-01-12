const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    {
        const file = try std.fs.cwd().openFile("./input.txt", .{});
        defer file.close();
        var buffered_reader = std.io.bufferedReader(file.reader());
        try stdout.print("Stage 1: {d}\n", .{try sum_small_dirs(allocator, buffered_reader.reader())});
    }

    {
        const file = try std.fs.cwd().openFile("./input.txt", .{});
        defer file.close();
        var buffered_reader = std.io.bufferedReader(file.reader());
        try stdout.print("Stage 2: {d}\n", .{try smallest_big_enough_dir(allocator, buffered_reader.reader())});
    }

    try bw.flush();
}

fn sum_small_dirs(allocator: Allocator, reader: anytype) !usize {
    var map = try dir_sizes(allocator, reader);
    defer {
        for (map.keys()) |key| {
            allocator.free(key);
        }
        map.deinit();
    }

    var total: usize = 0;
    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        const size = entry.value_ptr.*;

        if (size > 100000) continue;
        total += size;
    }
    return total;
}

fn smallest_big_enough_dir(allocator: Allocator, reader: anytype) !usize {
    var map = try dir_sizes(allocator, reader);
    defer {
        for (map.keys()) |key| {
            allocator.free(key);
        }
        map.deinit();
    }

    var total: usize = map.get("/").?;

    var free_space: usize = 70000000 - total;
    var space_to_free: usize = 30000000 - free_space;

    var best_size: usize = 70000000;
    for (map.values()) |size| {
        if (size >= space_to_free and size < best_size) {
            best_size = size;
        }
    }

    return best_size;
}

// fn dir_sizes(allocator: Allocator, reader: anytype) !std.array_hash_map.ArrayHashMap([]const u8, usize, std.array_hash_map.StringContext, true) {
fn dir_sizes(allocator: Allocator, reader: anytype) !std.StringArrayHashMap(usize) {
    // fn dir_sizes(allocator: Allocator, reader: anytype) !usize {
    var map = std.StringArrayHashMap(usize).init(allocator);

    var buf = try allocator.alloc(u8, 32);
    defer allocator.free(buf);

    var current_dir = std.ArrayList([]const u8).init(allocator);
    defer {
        while (current_dir.popOrNull()) |dir| {
            allocator.free(dir);
        }

        current_dir.deinit();
    }

    while (try reader.readUntilDelimiterOrEof(buf, '\n')) |line| {
        if (std.mem.startsWith(u8, line, "$")) {
            const command = parse_command(line);
            if (!std.mem.startsWith(u8, command, "cd ")) {
                continue;
            }

            var destination = parse_destination(command);

            if (std.mem.eql(u8, destination, "..")) {
                allocator.free(current_dir.pop());
                continue;
            }

            try current_dir.append(try copy_slice_value(allocator, destination));
            continue;
        }

        if (std.mem.startsWith(u8, line, "dir")) {
            continue;
        }

        const file_size = try parse_file_size(line);

        var current_dir_copy = try current_dir.clone();
        defer current_dir_copy.deinit(); // We don't need to clear each path piece because they're managed by "current_dir"

        while (true) {
            const pathname = try std.mem.join(allocator, "/", current_dir_copy.items);
            const entry = try map.getOrPutValue(pathname, 0);
            const dir_size = entry.value_ptr.* + file_size;
            try map.put(pathname, dir_size);

            // If we already had an existing entry, then the hashmap will use the string it already has
            // instead of taking ownership of this one. That leaves us responsible for freeing it.
            if (entry.found_existing) {
                allocator.free(pathname);
            }
            _ = current_dir_copy.pop();
            if (current_dir_copy.items.len == 0) break;
        }
    }

    return map;
}

// Copy the slice by value so it's underlying buffer can be re-used
fn copy_slice_value(allocator: Allocator, slice: []const u8) ![]const u8 {
    var new_slice = try allocator.alloc(u8, slice.len);
    std.mem.copy(u8, new_slice, slice);
    return new_slice;
}

fn parse_file_size(line: []const u8) !usize {
    var parts = std.mem.split(u8, line, " ");
    return try std.fmt.parseUnsigned(usize, parts.first(), 10);
}

// Returns a pointer to the portion of the slice that contains the command. If you want
// to use the return value for something that outlives the original slice, you'll need to
// copy it using copy_slice_value.
fn parse_command(line: []const u8) []const u8 {
    return std.mem.trimLeft(u8, line, "$ ");
}

// Returns a pointer of the portion of the slice that contains the destination. If you want
// to use the return value for something that outlives the original slice, you'll need to
// copy it using copy_slice_value.
fn parse_destination(line: []const u8) []const u8 {
    return std.mem.trimLeft(u8, line, "cd ");
}

const expectEqual = std.testing.expectEqual;
const test_allocator = std.testing.allocator;

test "sum_small_dirs empty root" {
    std.debug.print("\n", .{});
    var br = std.io.fixedBufferStream(
        \\$ cd /
        \\$ ls
    );

    const result = try sum_small_dirs(test_allocator, br.reader());
    try std.testing.expectEqual(@as(usize, 0), result);
}

test "sum_small_dirs one file" {
    std.debug.print("\n", .{});
    var br = std.io.fixedBufferStream(
        \\$ cd /
        \\$ ls
        \\123 b.txt
    );

    const result = try sum_small_dirs(test_allocator, br.reader());
    try std.testing.expectEqual(@as(usize, 123), result);
}

test "sum_small_dirs two files, one nested" {
    std.debug.print("\n", .{});
    var br = std.io.fixedBufferStream(
        \\$ cd /
        \\$ ls
        \\dir a
        \\123 b.txt
        \\$ cd a
        \\$ ls
        \\456 c.txt
    );

    // root:
    // 123 + 456 = 579
    // dir a:
    // 456
    // total = 579 + 456 = 1035
    const result = try sum_small_dirs(test_allocator, br.reader());
    try std.testing.expectEqual(@as(usize, 1035), result);
}

test "sum_small_dirs inner dir makes outer too big" {
    std.debug.print("\n", .{});
    var br = std.io.fixedBufferStream(
        \\$ cd /
        \\$ ls
        \\dir a
        \\123 b.txt
        \\$ cd a
        \\$ ls
        \\99999 c.txt
    );

    // root:
    // 123 + 99999 = 100122 (!)
    // dir a:
    // 99999
    // total = 0 + 99999 = 99999
    const result = try sum_small_dirs(test_allocator, br.reader());
    try std.testing.expectEqual(@as(usize, 99999), result);
}

test "sum_small_dirs example 1" {
    var br = std.io.fixedBufferStream(
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    );

    const result = try sum_small_dirs(test_allocator, br.reader());
    try std.testing.expectEqual(@as(usize, 95437), result);
}

test "smallest_big_enough_dir example 1" {
    var br = std.io.fixedBufferStream(
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    );

    const result = try smallest_big_enough_dir(test_allocator, br.reader());
    try std.testing.expectEqual(@as(usize, 24933642), result);
}
