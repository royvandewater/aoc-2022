const input = @import("./input.zig");

const Stage1 = struct {

  pub fn answer(self: *Stage1) usize {
    _ = self;
    return 0;
  }
};

fn init(in: input.Input) Stage1 {
  _ = in;
  return Stage1{};
}