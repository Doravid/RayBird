const rl = @import("raylib");
const gui = @import("raygui");

const game = @import("..\\game.zig");
const std = @import("std");
const player = @import("..\\player.zig");
const levelEditor = @import("levelEditor.zig");
pub const level = struct {
    map: [9][16]game.blockType,
    player: []rl.Vector2,
    const Self = @This();
    pub fn init(map: [9][16]game.blockType, playerA: []rl.Vector2) Self {
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
        std.debug.print("Failed to Merge the int and the string: {}", .{err});
        return level.init(player.mat16x9, &[_]rl.Vector2{});
    };
    const path = alloc.alloc(u8, newPrefix.len + suffix.len) catch |err| {
        std.debug.print("Failed to allocate memory for the path: {}\n", .{err});
        return level.init(player.mat16x9, &[_]rl.Vector2{});
    };
    std.mem.copyForwards(u8, path[0..], newPrefix);
    std.mem.copyForwards(u8, path[newPrefix.len..], suffix);
    const jsonData = std.fs.cwd().readFileAlloc(alloc, path, 2048) catch |err| {
        std.debug.print("Failed to read the file: {}", .{err});
        return level.init(player.mat16x9, &[_]rl.Vector2{});
    };

    const result = std.json.parseFromSlice(level, alloc, jsonData, .{
        .ignore_unknown_fields = true,
    }) catch |err| {
        std.debug.print("Failed to parse json: {}", .{err});
        return level.init(player.mat16x9, &[_]rl.Vector2{});
    };

    return result.value;
}

var maxLevelUnlocked: usize = 0;

var currentLevelNumber: usize = 0;
pub fn setLevel(levelNumber: u32) void {
    player.clearPlayer();
    const levelA = loadLevelFromJson(levelNumber);
    currentLevelNumber = levelNumber;
    if (levelNumber > maxLevelUnlocked) {
        maxLevelUnlocked = levelNumber - 1;
    }
    for (levelA.player) |elem| {
        const newBody = rl.Vector2{ .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 16 * (elem.x / 120), .y = @as(f32, @floatFromInt(rl.getScreenWidth())) / 16 * (elem.y / 120) };
        player.body.append(newBody) catch |err| {
            std.debug.print("Failed to append position: {}\n", .{err});
            return;
        };
    }
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

pub const menuType = enum { main, levelSelect, pauseMenu, levelEditor, optionsMenu };
pub var currentMenu: menuType = menuType.main;
const levelSelectRowSize: i32 = 6;
pub fn loadMenu() bool {
    if (currentMenu == menuType.main) {
        const levelSelect_button = gui.guiButton(rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .width = 4.0 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - game.boxSize * 4)) / 2.0), .y = 1.5 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16 }, "Level Select");
        const levelEditor_button = gui.guiButton(rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .width = 4.0 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - game.boxSize * 4)) / 2.0), .y = 3.5 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16 }, "Level Editor");
        const quitGame_button = gui.guiButton(rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .width = 4.0 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - game.boxSize * 4)) / 2.0), .y = 5.5 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16 }, "Quit");
        const options_button = gui.guiButton(rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .width = 4.0 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - game.boxSize * 4)) / 2.0), .y = 5.5 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16 }, "Options");

        if (levelSelect_button == 1) {
            currentMenu = menuType.levelSelect;
        }
        if (levelEditor_button == 1) {
            currentMenu = menuType.levelEditor;
            player.clearPlayerAndMap();
            levelEditor.body.clearAndFree();
            return false;
        }
        if (options_button == 1) {
            currentMenu = menuType.optionsMenu;
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
            const levelButton = gui.guiButton(rl.Rectangle{ .height = 2.0 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .width = 2.0 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .x = (@as(f32, @floatFromInt(rl.getScreenWidth() * (@mod(i, levelSelectRowSize)))) / 6.0) + 60, .y = @as(f32, @floatFromInt(@divTrunc(rl.getScreenWidth(), 6 * 16) + game.boxSize * @divTrunc(i, 6))) * 2.5 }, curLevel);
            if (levelButton == 1) {
                setLevel(@intCast(i + 1));
                return false;
            }

            i += 1;
        }
    }

    return true;
}
