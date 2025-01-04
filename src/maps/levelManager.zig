const game = @import("..\\game.zig");
const std = @import("std");
const player = @import("..\\player.zig");

const levels = [_][9][16]game.blockType{
    @import("level1.zig").level,
    @import("level2.zig").level,
};
pub var currentLevel = levels[0];
var currentLevelNumber: usize = 0;
pub fn setLevel(levelNumber: usize) void {
    const size: i32 = @intCast(levels.len);
    if (levelNumber < 0 or levelNumber > size) return;
    currentLevel = levels[levelNumber];
    currentLevelNumber = levelNumber;
    std.debug.print("Load Level {}\n", .{levelNumber});
    player.initPlayer();
}
pub fn getLevel() [9][16]game.blockType {
    return currentLevel;
}

pub fn loadLevel(x: i16) !void {
    if (x > levels.len) return;
    currentLevel = levels[x - 1];
}
