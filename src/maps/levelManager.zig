const game = @import("..\\game.zig");
const std = @import("std");
const player = @import("..\\player.zig");

//I really dislike how this is done but I dislike how arrays in zig are handled even more... so this is what I get.
const maps = [_][9][16]game.blockType{
    @import("level1.zig").map,
    @import("level2.zig").map,
};
const bodies = [_][]player.pos{
    @constCast(&@import("level1.zig").snake),
    @constCast(&@import("level2.zig").snake),
};

var currentLevel = maps[0];

var currentLevelNumber: usize = 0;
pub fn setLevel(levelNumber: usize) void {
    const size: i32 = @intCast(maps.len);

    if (levelNumber < 0 or levelNumber >= size) return;
    currentLevel = maps[levelNumber];

    currentLevelNumber = levelNumber;
    player.initPlayer();
}

pub fn getLevelMap() [9][16]game.blockType {
    return maps[currentLevelNumber];
}
pub fn getBody() []player.pos {
    return bodies[currentLevelNumber];
}
