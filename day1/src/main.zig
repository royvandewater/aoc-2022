const std = @import("std");
const Input = @import("./input.zig").Input;
const Stage1 = @import("./stage_1.zig").Stage1;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("./input.txt", .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const in_stream = buffered_reader.reader();

    const stdout_file = std.io.getStdOut().writer();
    var out_stream = std.io.bufferedWriter(stdout_file);
    const stdout = out_stream.writer();

    var input = try Input.parse(allocator, in_stream);
    defer input.deinit();

    var stage_1 = try Stage1.init(allocator, &input);
    defer stage_1.deinit();

    try stdout.print("stage 1: {d}\n", .{stage_1.answer()});

    try out_stream.flush();
}
