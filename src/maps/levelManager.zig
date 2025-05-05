const rl = @import("raylib");
const gui = @import("raygui");

const game = @import("..\\game.zig");
const std = @import("std");
const player = @import("..\\player.zig");
const levelEditor = @import("levelEditor.zig");
pub const level = struct {
    map: [9][16]game.blockType,
    player: []player.pos,
    const Self = @This();
    pub fn init(map: [9][16]game.blockType, playerA: []player.pos) Self {
        return .{ .map = map, .player = playerA };
    }
};

pub var currentLevelNum = 0;

pub fn loadLevelFromJson(name: u32) level {
    var thing = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = thing.allocator();

    const prefix = "./src/maps/level";
    const suffix = ".json";

    const newPrefix = std.fmt.allocPrint(alloc, "{s}{d}", .{ prefix, name }) catch |err| {
        std.debug.print("9999999999999{}", .{err});
        return level.init(player.mat16x9, &[_]player.pos{});
    };
    const path = alloc.alloc(u8, newPrefix.len + suffix.len) catch |err| {
        std.debug.print("Failed to allocate: {}\n", .{err});
        return level.init(player.mat16x9, &[_]player.pos{});
    };
    std.mem.copyForwards(u8, path[0..], newPrefix);
    std.mem.copyForwards(u8, path[newPrefix.len..], suffix);
    const jsonData = std.fs.cwd().readFileAlloc(alloc, path, 2048) catch |err| {
        std.debug.print("00000000000000{}", .{err});
        return level.init(player.mat16x9, &[_]player.pos{});
    };

    const result = std.json.parseFromSlice(level, alloc, jsonData, .{
        .ignore_unknown_fields = true,
    }) catch |err| {
        std.debug.print("---------{}", .{err});
        return level.init(player.mat16x9, &[_]player.pos{});
    };

    return result.value;
}

var maxLevelUnlocked: usize = 0;

var currentLevelNumber: usize = 0;
pub fn setLevel(levelNumber: u32) void {
    player.initPlayer();
    const levelA = loadLevelFromJson(levelNumber);
    currentLevelNumber = levelNumber;
    if (levelNumber > maxLevelUnlocked) {
        maxLevelUnlocked = levelNumber;
    }
    std.debug.print("tempBody {any}\n", .{levelA.player});
    for (levelA.player) |elem| {
        player.body.append(elem) catch |err| {
            std.debug.print("Failed to append position: {}\n", .{err});
            return;
        };
    }
    std.debug.print("tempBody {any}\n", .{player.body.items});
    player.mat16x9 = levelA.map;
}
pub fn getCurrentLevelNum() usize {
    return currentLevelNumber;
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
            const curLevel = numAsString.ptr;
            const levelButton = gui.guiButton(rl.Rectangle{ .height = 2.0 * @as(f32, @floatFromInt(game.boxSize)), .width = 2.0 * @as(f32, @floatFromInt(game.boxSize)), .x = (@as(f32, @floatFromInt(game.screenWidth * (@mod(i, levelSelectRowSize)))) / 6.0) + 60, .y = @as(f32, @floatFromInt(@divTrunc(game.boxSize, 6) + game.boxSize * @divTrunc(i, 6))) * 2.5 }, curLevel);
            if (levelButton == 1) {
                setLevel(@intCast(i + 1));
                return false;
            }

            i += 1;
        }
    }

    return true;
}
