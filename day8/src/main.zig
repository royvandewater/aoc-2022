const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("./input.txt", .{});
    defer file.close();

    const input = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    const trees = try stringToGrid(allocator, input);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Stage 1: {d}\n", .{try countVisibleTrees(allocator, trees)});


    try bw.flush(); // don't forget to flush!
}

fn countVisibleTrees(allocator: Allocator, grid: [][]usize) !usize {
    var count: usize = countEdgeTrees(grid);

    for (grid) |row, y| {
        if (y == 0 or y == grid.len - 1) continue;

        for (row) |tree, x| {
            if (x == 0 or x == row.len - 1) continue;
            if (!try visible(allocator, grid, tree, x, y)) continue;

            count += 1;
        }
    }

    return count;
}

fn countEdgeTrees(grid: [][]usize) usize {
    var col_length = grid.len;
    var row_length = grid[0].len;

    return (2 * col_length) + (2 * row_length) - 4;
}

fn visible(allocator: Allocator, grid: [][]usize, tree: usize, x: usize, y: usize) !bool {
    return visibleRow(grid, tree, x, y) or try visibleColumn(allocator, grid, tree, x, y);
}

fn visibleRow(grid: [][]usize, tree: usize, x: usize, y: usize) bool {
    var row = grid[y];
    var before = row[0..x];
    var after = row[x+1..];

    return allTreesShorter(tree, before) or allTreesShorter(tree, after);
}

fn visibleColumn(allocator: Allocator, grid: [][]usize, tree: usize, x: usize, y: usize) !bool {
    var column = try allocator.alloc(usize, grid.len);
    defer allocator.free(column);

    var i: usize = 0;
    while (i < grid.len) {
        column[i] = grid[i][x];
        i += 1;
    }

    var before = column[0..y];
    var after = column[y+1..];

    return allTreesShorter(tree, before) or allTreesShorter(tree, after);
}

fn allTreesShorter(tree: usize, seq: []usize) bool {
    for (seq) |item| {
        if (item >= tree) return false;
    }

    return true;
}

fn stringToGrid(allocator: Allocator, input: []const u8) ![][]usize {
    var list = std.ArrayList(std.ArrayList(usize)).init(allocator);
    defer {
        while (list.popOrNull()) |row| {
            row.deinit();
        }
        list.deinit();
    }

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        var line_list = try std.ArrayList(usize).initCapacity(allocator, line.len);

        for (line) |char| {
            const char_string: []const u8 = &[_]u8{char};
            const value = try std.fmt.parseUnsigned(usize, char_string, 10);
            line_list.appendAssumeCapacity(value);
        }

        try list.append(line_list);
    }

    var slice = try allocator.alloc([]usize, list.items.len);
    for (list.items) |row, i| {
        var row_slice = try allocator.alloc(usize, row.items.len);
        std.mem.copy(usize, row_slice, row.items);
        slice[i] = row_slice;
    }
    return slice;
}

fn free_trees(allocator: Allocator, trees: [][]usize) void {
    for (trees) |row| {
        allocator.free(row);
    }
    allocator.free(trees);
}

var expectEqual = std.testing.expectEqual;
var test_allocator = std.testing.allocator;

test "countVisibleTrees 3x3 visible" {
    var trees = try stringToGrid(test_allocator,
        \\000
        \\010
        \\000
    );
    defer free_trees(test_allocator, trees);

    try std.testing.expectEqual(@as(usize, 9), try countVisibleTrees(test_allocator, trees));
}

test "countVisibleTrees 3x3 not visible" {
    var trees = try stringToGrid(test_allocator,
        \\222
        \\212
        \\222
    );
    defer free_trees(test_allocator, trees);

    try std.testing.expectEqual(@as(usize, 8), try countVisibleTrees(test_allocator, trees));
}

test "countVisibleTrees example 1" {
    var trees = try stringToGrid(test_allocator,
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    );
    defer free_trees(test_allocator, trees);

    try std.testing.expectEqual(@as(usize, 21), try countVisibleTrees(test_allocator, trees));
}
