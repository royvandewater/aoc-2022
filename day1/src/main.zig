const std = @import("std");
const input_parser = @import("./input.zig");
const stage_1 = @import("./stage_1.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("./input.txt", .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const in_stream = buffered_reader.reader();

    const stdout_file = std.io.getStdOut().writer();
    var out_stream = std.io.bufferedWriter(stdout_file);
    const stdout = out_stream.writer();

    const input = try input_parser.parseInput(allocator, in_stream);

    const answer_1 = stage_1.init(input.copy()).answer();

    try stdout.print("stage 1: {d}", .{answer_1});

    try out_stream.flush();
}
