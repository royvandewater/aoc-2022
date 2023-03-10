const std = @import("std");
const Input = @import("./input.zig").Input;
const Stage1 = @import("./stage_1.zig").Stage1;
const Stage2 = @import("./stage_2.zig").Stage2;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("./input.txt", .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const in_stream = buffered_reader.reader();

    const stdout_file = std.io.getStdOut().writer();
    var out_stream = std.io.bufferedWriter(stdout_file);
    const stdout = out_stream.writer();

    var input = try Input.fromReader(allocator, in_stream);
    defer input.deinit();

    var stage_1 = try Stage1.fromInput(allocator, &input);
    defer stage_1.deinit();
    var stage_1_answer = try stage_1.answer();
    defer allocator.free(stage_1_answer);
    try stdout.print("stage 1: {s}\n", .{stage_1_answer});

    var stage_2 = try Stage2.fromInput(allocator, &input);
    defer stage_2.deinit();
    var stage_2_answer = try stage_2.answer();
    defer allocator.free(stage_2_answer);
    try stdout.print("stage 2: {s}\n", .{stage_2_answer});

    try out_stream.flush();
}
