const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const file1 = try std.fs.cwd().openFile("./input.txt", .{});
    defer file1.close();
    var buffered_reader1 = std.io.bufferedReader(file1.reader());
    try stdout.print("Stage 1: {any}\n", .{find_marker(allocator, buffered_reader1.reader(), 4)});

    const file2 = try std.fs.cwd().openFile("./input.txt", .{});
    defer file2.close();
    var buffered_reader2 = std.io.bufferedReader(file2.reader());
    try stdout.print("Stage 2: {any}\n", .{find_marker(allocator, buffered_reader2.reader(), 14)});

    try bw.flush(); // don't forget to flush!
}

const MarkerNotFound = error {};

fn find_marker(allocator: Allocator, reader: anytype, length: usize) !usize {
    var last_chars = try std.ArrayList(u8).initCapacity(allocator, length);
    defer last_chars.deinit();
    var i: usize = 0;

    while (reader.readByte() catch null) |char| {
        try last_chars.append(char);
        while (last_chars.items.len > length) {
            _ = last_chars.orderedRemove(0);
        }

        if (last_chars.items.len == length and try unique(allocator, last_chars.items)) {
            return i + 1;
        }

        i += 1;
    }

    return error.MarkerNotFound;
}

fn unique(allocator: Allocator, chars: []u8) !bool {
    var set = std.AutoHashMap(u8, void).init(allocator);
    defer set.deinit();

    for (chars) |char| {
        if (char == 0) {
            return false;
        }

        var previous = try set.fetchPut(char, {});
        if (previous != null) {
            return false;
        }
    }

    return true;
}

const expectEqual = std.testing.expectEqual;
const test_allocator = std.testing.allocator;

test "stage1 example 1" {
    var br = std.io.fixedBufferStream("mjqjpqmgbljsphdztnvjfqwrcgsmlb");
    const result = try find_marker(test_allocator, br.reader(), 4);
    try expectEqual(@as(usize, 7), result);
}

test "stage1 example 2" {
    var br = std.io.fixedBufferStream("bvwbjplbgvbhsrlpgdmjqwftvncz");
    const result = try find_marker(test_allocator, br.reader(), 4);
    try expectEqual(@as(usize, 5), result);
}

test "stage1 example 3" {
    var br = std.io.fixedBufferStream("nppdvjthqldpwncqszvftbrmjlhg");
    const result = try find_marker(test_allocator, br.reader(), 4);
    try expectEqual(@as(usize, 6), result);
}

test "stage1 example 4" {
    var br = std.io.fixedBufferStream("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg");
    const result = try find_marker(test_allocator, br.reader(), 4);
    try expectEqual(@as(usize, 10), result);
}

test "stage1 example 5" {
    var br = std.io.fixedBufferStream("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw");
    const result = try find_marker(test_allocator, br.reader(), 4);
    try expectEqual(@as(usize, 11), result);
}

test "stage2 example 1" {
    var br = std.io.fixedBufferStream("mjqjpqmgbljsphdztnvjfqwrcgsmlb");
    const result = try find_marker(test_allocator, br.reader(), 14);
    try expectEqual(@as(usize, 19), result);
}

test "stage2 example 2" {
    var br = std.io.fixedBufferStream("bvwbjplbgvbhsrlpgdmjqwftvncz");
    const result = try find_marker(test_allocator, br.reader(), 14);
    try expectEqual(@as(usize, 23), result);
}

test "stage2 example 3" {
    var br = std.io.fixedBufferStream("nppdvjthqldpwncqszvftbrmjlhg");
    const result = try find_marker(test_allocator, br.reader(), 14);
    try expectEqual(@as(usize, 23), result);
}

test "stage2 example 4" {
    var br = std.io.fixedBufferStream("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg");
    const result = try find_marker(test_allocator, br.reader(), 14);
    try expectEqual(@as(usize, 29), result);
}

test "stage2 example 5" {
    var br = std.io.fixedBufferStream("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw");
    const result = try find_marker(test_allocator, br.reader(), 14);
    try expectEqual(@as(usize, 26), result);
}