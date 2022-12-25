const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("./input.txt", .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const in_stream = buffered_reader.reader();
    const input = try in_stream.readAllAlloc(allocator, std.math.maxInt(usize));

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Stage 1: {any}\n", .{try stage1(input)});
    try stdout.print("Stage 2: {any}\n", .{try stage2(input)});

    try bw.flush(); // don't forget to flush!
}

const Range = [2]usize;

fn stage1(str: []const u8) !usize {
    var total: usize = 0;

    var lines = std.mem.split(u8, str, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const ranges = try parseRanges(line);

        if (totalRangeOverlap(ranges[0], ranges[1])) {
            total += 1;
        }
    }

    return total;
}

fn stage2(str: []const u8) !usize {
    var total: usize = 0;

    var lines = std.mem.split(u8, str, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const ranges = try parseRanges(line);

        if (partialRangeOverlap(ranges[0], ranges[1])) {
            total += 1;
        }
    }

    return total;
}

fn totalRangeOverlap(range_1: Range, range_2: Range) bool {
    const range_1_overlaps_2 = range_1[0] <= range_2[0] and range_1[1] >= range_2[1];
    const range_2_overlaps_1 = range_2[0] <= range_1[0] and range_2[1] >= range_1[1];

    return range_1_overlaps_2 or range_2_overlaps_1;
}

fn partialRangeOverlap(range_1: Range, range_2: Range) bool {
    const total_range_overlap = totalRangeOverlap(range_1, range_2);
    const range_1_overlaps_2 = range_2[0] <= range_1[0] and range_2[1] >= range_1[0];
    const range_2_overlaps_1 = range_1[0] <= range_2[0] and range_1[1] >= range_2[0];

    return total_range_overlap or range_1_overlaps_2 or range_2_overlaps_1;
}

fn parseRanges(line: []const u8) ![2]Range {
    var assignments = std.mem.split(u8, line, ",");

    return [2]Range{
        try parseRange(assignments.first()),
        try parseRange(assignments.rest()),
    };
}

fn parseRange(assignment: []const u8) !Range {
    var range_parts = std.mem.split(u8, assignment, "-");
    const min = try std.fmt.parseUnsigned(usize, range_parts.first(), 10);
    const max = try std.fmt.parseUnsigned(usize, range_parts.rest(), 10);
    return Range{ min, max };
}

test "stage 1: empty" {
    const answer = try stage1("");
    try std.testing.expectEqual(@as(usize, 0), answer);
}

test "stage 1: example 1" {
    const answer = try stage1(
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
    );

    try std.testing.expectEqual(@as(usize, 2), answer);
}

test "stage 2: empty" {
    const answer = try stage2("");
    try std.testing.expectEqual(@as(usize, 0), answer);
}

test "stage 2: example 1" {
    const answer = try stage2(
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
    );

    try std.testing.expectEqual(@as(usize, 4), answer);
}
