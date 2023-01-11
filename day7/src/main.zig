const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const file = try std.fs.cwd().openFile("./input.txt", .{});
    defer file.close();
    var buffered_reader = std.io.bufferedReader(file.reader());
    try stdout.print("Stage 1: {d}\n", .{try sum_small_dirs(allocator, buffered_reader.reader())});

    // const file2 = try std.fs.cwd().openFile("./input.txt", .{});
    // defer file2.close();
    // var buffered_reader2 = std.io.bufferedReader(file2.reader());
    // try stdout.print("Stage 2: {any}\n", .{find_marker(allocator, buffered_reader2.reader(), 14)});

    try bw.flush(); // don't forget to flush!
}

fn sum_small_dirs(allocator: Allocator, reader: anytype) !usize {
    var buf = try allocator.alloc(u8, 32);
    defer allocator.free(buf);

    var current_dir_total: usize = 0;
    var total: usize = 0;

    while (try reader.readUntilDelimiterOrEof(buf, '\n')) |line| {
        if (std.mem.startsWith(u8, line, "$")) {
            const command = parse_command(line);
            if (!std.mem.startsWith(u8, command, "cd ")) {
                continue;
            }

            const destination = parse_destination(command);
            if (std.mem.eql(u8, destination, "/")) {
                continue;
            }

            if (std.mem.eql(u8, destination, "..")) {
                break;
            }

            const sub_dir_size = try sum_small_dirs(allocator, reader);

            current_dir_total += sub_dir_size;
            total += sub_dir_size;
            continue;
        }

        if (std.mem.startsWith(u8, line, "dir")) {
            continue;
        }

        const file_size = try parse_file_size(line);
        current_dir_total += file_size;
    }

    if (current_dir_total <= 100000) {
        total += current_dir_total;
    }
    return total;
}

fn parse_file_size(line: []const u8) !usize {
    var parts = std.mem.split(u8, line, " ");
    return try std.fmt.parseUnsigned(usize, parts.first(), 10);
}

fn parse_command(line: []const u8) []const u8 {
    return std.mem.trimLeft(u8, line, "$ ");
}

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
