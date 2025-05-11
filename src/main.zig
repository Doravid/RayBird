const game = @import("game.zig");
const std = @import("std");
const rl = @import("raylib");

pub fn main() anyerror!void {
    //To set config flags
    const myFlag = rl.ConfigFlags{
        .msaa_4x_hint = true,
    };
    rl.setConfigFlags(myFlag);

    try game.runGame();
}
