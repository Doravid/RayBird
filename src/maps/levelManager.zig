const game = @import("..\\game.zig");

const levels = [_][9][16]game.blockType{
    @import("level1.zig").level,
    @import("level2.zig").level,
};
pub var currentLevel = levels[0];

pub fn setLevel(levelNumber: i32) void {
    const size: i32 = @intCast(levels.len);
    if (levelNumber < 1 or levelNumber > size) {}
}
pub fn getLevel() [9][16]game.blockType {
    return currentLevel;
}
