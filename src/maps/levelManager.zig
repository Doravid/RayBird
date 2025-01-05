const game = @import("..\\game.zig");
const std = @import("std");
const player = @import("..\\player.zig");

const levels = [_]type{
    @import("level1.zig"),
    @import("level2.zig"),
};

// const levels = [_][9][16]game.blockType{
//     @import("level1.zig").level,
//     @import("level2.zig").level,
// };

var currentBody = levels[0].snake;

var currentLevelNumber: usize = 0;
pub fn setLevel(levelNumber: usize) void {
    const size: i32 = @intCast(levels.len);
    if (levelNumber < 0 or levelNumber > size) return;
    currentBody = levels[0].snake;
    currentLevelNumber = levelNumber;
    player.initPlayer();
}
pub fn getLevel() [9][16]game.blockType {
    return levels[currentLevelNumber].level;
}
pub fn getBody() []player.pos {
    return currentBody;
}
