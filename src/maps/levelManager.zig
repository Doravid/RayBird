const rl = @import("raylib");
const gui = @import("raygui");

const game = @import("..\\game.zig");
const std = @import("std");
const player = @import("..\\player.zig");
const levelEditor = @import("levelEditor.zig");

//I really dislike how this is done but I dislike how arrays in zig are handled even more... so this is what I get.
//START OF PER LEVEl IMPORTS, MUST DO BOTH.
const maps = [_][9][16]game.blockType{
    @import("level1.zig").map,
    @import("level2.zig").map,
    //Testing
    @import("level2.zig").map,
    @import("level2.zig").map,
    @import("level2.zig").map,
    @import("level2.zig").map,
    @import("level2.zig").map,
    @import("level2.zig").map,
};
const bodies = [_][]player.pos{
    @constCast(&@import("level1.zig").snake),
    @constCast(&@import("level2.zig").snake),
    //Testing
    @constCast(&@import("level2.zig").snake),
    @constCast(&@import("level2.zig").snake),
    @constCast(&@import("level2.zig").snake),
    @constCast(&@import("level2.zig").snake),
    @constCast(&@import("level2.zig").snake),
    @constCast(&@import("level2.zig").snake),
};
//END OF PER LEVEL IMPORTS

pub const numLevels: i32 = maps.len;

var currentLevel = maps[0];
var maxLevelUnlocked: usize = 0;

var currentLevelNumber: usize = 0;
pub fn setLevel(levelNumber: usize) void {
    const size: i32 = @intCast(maps.len);

    if (levelNumber < 0 or levelNumber >= size) return;
    currentLevel = maps[levelNumber];

    currentLevelNumber = levelNumber;
    if (levelNumber > maxLevelUnlocked) {
        maxLevelUnlocked = levelNumber;
    }
    player.initPlayer();
}

pub fn getLevelMap() [9][16]game.blockType {
    return maps[currentLevelNumber];
}
pub fn getCurrentLevelNum() usize {
    return currentLevelNumber;
}
pub fn getBody() []player.pos {
    return bodies[currentLevelNumber];
}
pub fn checkPause() bool {
    if (currentMenu == menuType.levelEditor) {
        levelEditor.loadLevelEditor();
    }
    if (rl.isKeyPressed(rl.KeyboardKey.escape)) {
        currentMenu = menuType.main;
        return true;
    }

    return false;
}

pub const menuType = enum { main, levelSelect, pauseMenu, levelEditor };
pub var currentMenu: menuType = menuType.main;
const levelSelectRowSize: i32 = 6;
pub fn loadMenu() bool {
    if (currentMenu == menuType.main) {
        const startGame_button = gui.guiButton(rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(game.boxSize)), .width = 4.0 * @as(f32, @floatFromInt(game.boxSize)), .x = (@as(f32, @floatFromInt(game.screenWidth)) / 2.0) - 240.0, .y = 80 }, "Start Game!");
        const levelSelect_button = gui.guiButton(rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(game.boxSize)), .width = 4.0 * @as(f32, @floatFromInt(game.boxSize)), .x = (@as(f32, @floatFromInt(game.screenWidth)) / 2.0) - 240.0, .y = 320 }, "Level Select");
        const quitGame_button = gui.guiButton(rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(game.boxSize)), .width = 4.0 * @as(f32, @floatFromInt(game.boxSize)), .x = (@as(f32, @floatFromInt(game.screenWidth)) / 2.0) - 240.0, .y = 560 }, "Quit");
        const levelEditor_button = gui.guiButton(rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(game.boxSize)), .width = 4.0 * @as(f32, @floatFromInt(game.boxSize)), .x = (@as(f32, @floatFromInt(game.screenWidth)) / 2.0) - 240.0, .y = 800 }, "Level Editor");

        if (startGame_button == 1) {
            return false;
        }
        if (levelSelect_button == 1) {
            currentMenu = menuType.levelSelect;
        }
        if (levelEditor_button == 1) {
            currentMenu = menuType.levelEditor;
            player.clearPlayerAndMap();
            return false;
        }
        if (quitGame_button == 1) {
            rl.closeWindow();
        }
    }
    if (currentMenu == menuType.levelSelect) {
        var i: i32 = 0;
        while (i < maxLevelUnlocked + 1) {
            const max_len = 20;
            var buf: [max_len]u8 = undefined;
            const numAsString = std.fmt.bufPrintZ(&buf, "{}", .{i + 1}) catch |err| {
                std.debug.print("{}", .{err});
                return true;
            };
            const level = numAsString.ptr;
            const levelButton = gui.guiButton(rl.Rectangle{ .height = 2.0 * @as(f32, @floatFromInt(game.boxSize)), .width = 2.0 * @as(f32, @floatFromInt(game.boxSize)), .x = (@as(f32, @floatFromInt(game.screenWidth * (@mod(i, levelSelectRowSize)))) / 6.0) + 60, .y = @as(f32, @floatFromInt(@divTrunc(game.boxSize, 6) + game.boxSize * @divTrunc(i, 6))) * 2.5 }, level);
            if (levelButton == 1) {
                setLevel(@intCast(i));
                return false;
            }

            i += 1;
        }
    }

    return true;
}
