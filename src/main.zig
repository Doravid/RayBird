const game = @import("game.zig");
const std = @import("std");

pub fn main() anyerror!void {
    game.runGame();
}
