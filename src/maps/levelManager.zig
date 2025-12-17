const rl = @import("raylib");
const gui = @import("raygui");

const game = @import("../game.zig");
const boxes = @import("../boxes.zig");
const std = @import("std");
const player = @import("../player.zig");
const levelEditor = @import("levelEditor.zig");
const builtin = @import("builtin");

const air = game.blockType.air;
pub var mat16x9 = [9][16]game.blockType{
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]game.blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
};
pub const level = struct {
    map: [9][16]game.blockType,
    player: [][]rl.Vector2,
    boxes: [][]rl.Vector2,
    const Self = @This();
    pub fn init(map: [9][16]game.blockType, playerA: []rl.Vector2) Self {
        return .{ .map = map, .player = playerA };
    }
};

// pub const moveable = struct {
//     boxes: []rl.Vector2,
//     const Self = @This();
//     pub fn init(boxes: []rl.Vector2) Self {
//         return .{ .player = boxes };
//     }
// };

pub var currentLevelNum = 0;

// Embedded level files for WASM
const embedded_levels = if (builtin.target.os.tag == .emscripten or true) struct {
    const level1 = @embedFile("./level1.json");
    const level2 = @embedFile("./level2.json");
    const level3 = @embedFile("./level3.json");
    const level4 = @embedFile("./level4.json");
    const level5 = @embedFile("./level5.json");

    pub fn getLevelData(level_num: u32) ?[]const u8 {
        return switch (level_num) {
            1 => level1,
            2 => level2,
            3 => level3,
            4 => level4,
            5 => level5,
            else => null,
        };
    }
} else struct {
    pub fn getLevelData(level_num: u32) ?[]const u8 {
        _ = level_num;
        return null;
    }
};

pub fn loadLevelFromJson(name: u32) level {
    const alloc = std.heap.c_allocator;

    var jsonData: []const u8 = undefined;
    var should_free_json = false;

    const is_wasm = builtin.target.os.tag == .emscripten;

    if (is_wasm) {
        if (embedded_levels.getLevelData(name)) |data| {
            jsonData = data;
            std.log.info("Loading embedded level {}", .{name});
        } else {
            std.debug.print("Error: Level {} not found in embedded data (WASM target)\n", .{name});
            return level{ .map = mat16x9, .player = &[_][]rl.Vector2{}, .boxes = &[_][]rl.Vector2{} };
        }
    } else {
        const prefix = "./src/maps/level";
        const suffix = ".json";

        const newPrefix = std.fmt.allocPrint(alloc, "{s}{d}", .{ prefix, name }) catch |err| {
            std.debug.print("Failed to merge string and int for path: {}\n", .{err});
            return level{ .map = mat16x9, .player = &[_][]rl.Vector2{}, .boxes = &[_][]rl.Vector2{} };
        };
        defer alloc.free(newPrefix);

        const path = alloc.alloc(u8, newPrefix.len + suffix.len) catch |err| {
            std.debug.print("Failed to allocate memory for the path: {}\n", .{err});
            return level{ .map = mat16x9, .player = &[_][]rl.Vector2{}, .boxes = &[_][]rl.Vector2{} };
        };
        defer alloc.free(path);

        std.mem.copyForwards(u8, path[0..], newPrefix);
        std.mem.copyForwards(u8, path[newPrefix.len..], suffix);

        jsonData = std.fs.cwd().readFileAlloc(alloc, path, 2048) catch |err| {
            std.debug.print("Failed to read the file: {}. Ensure it exists and is accessible.\n", .{err});
            return level{ .map = mat16x9, .player = &[_][]rl.Vector2{}, .boxes = &[_][]rl.Vector2{} };
        };
        should_free_json = true;
    }

    defer if (should_free_json) alloc.free(jsonData);
    const result = std.json.parseFromSlice(level, alloc, jsonData, .{
        .ignore_unknown_fields = true,
    }) catch |err| {
        std.debug.print("Failed to parse json for level {}: {}\n", .{ name, err });
        return level{ .map = mat16x9, .player = &[_][]rl.Vector2{}, .boxes = &[_][]rl.Vector2{} };
    };

    return result.value;
}

var maxLevelUnlocked: usize = 0;

var currentLevelNumber: usize = 0;

pub fn setLevel(levelNumber: u32) void {
    std.debug.print(":pensive:\n", .{});
    player.clearPlayer();
    std.debug.print(":clearedPlayer:\n", .{});
    const levelA = loadLevelFromJson(levelNumber);
    std.debug.print(":levelLoaded!!:\n", .{});
    currentLevelNumber = levelNumber;
    if (levelNumber > maxLevelUnlocked) {
        maxLevelUnlocked = levelNumber - 1;
    }
    for (levelA.player) |playerSlice| {
        var newPlayer = std.ArrayList(rl.Vector2).init(std.heap.c_allocator);
        newPlayer.appendSlice(playerSlice) catch |err| {
            std.debug.print("Failed to append player slice: {}\n", .{err});
            return;
        };
        player.playerList.append(newPlayer) catch |err| {
            std.debug.print("Failed to append player: {}\n", .{err});
            return;
        };
    }
    // std.debug.print("players: {any}", .{player.playerList.items});
    for (levelA.boxes) |slice| {
        var group = std.ArrayList(rl.Vector2).init(std.heap.c_allocator);
        group.appendSlice(slice) catch |err| {
            std.debug.print("Failed to append box slice: {}\n", .{err});
            return;
        };
        boxes.boxList.append(group) catch |err| {
            std.debug.print("Failed to append box group: {}\n", .{err});
            return;
        };
    }
    mat16x9 = levelA.map;

    for (player.playerList.items) |playerBody| {
        for (playerBody.items) |segment| {
            std.debug.print("segment: {}", .{segment});
            game.setBlockWorldGrid(segment.x, segment.y, game.blockType.bdy);
        }
    }

    player.fruitNumber = player.numFruit();
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

const numResolutions = 4;
var curRes: usize = 1;
const resolutions: [numResolutions][*:0]const u8 = [numResolutions][*:0]const u8{ "1280 x 720", "1920 x 1080", "2560x1440", "4096 x 2160" };
const resolutionVecs = [_]rl.Vector2{ rl.Vector2{ .x = 1280, .y = 720 }, rl.Vector2{ .x = 1920, .y = 1080 }, rl.Vector2{ .x = 2560, .y = 1440 }, rl.Vector2{ .x = 4096, .y = 2160 } };

pub fn loadMenu() bool {
    if (currentMenu == menuType.main) {
        const screen_width_f = @as(f32, @floatFromInt(rl.getScreenWidth()));
        const button_height = 1.25 * screen_width_f / 16;
        const button_width = 4.0 * screen_width_f / 16;
        const button_x = (screen_width_f - @as(f32, @floatFromInt(game.boxSize * 4))) / 2.0;

        const levelSelect_button = gui.guiButton(rl.Rectangle{ .height = button_height, .width = button_width, .x = button_x, .y = 1.5 * screen_width_f / 16 }, "Level Select");
        const levelEditor_button = gui.guiButton(rl.Rectangle{ .height = button_height, .width = button_width, .x = button_x, .y = 3 * screen_width_f / 16 }, "Level Editor");
        const options_button = gui.guiButton(rl.Rectangle{ .height = button_height, .width = button_width, .x = button_x, .y = 4.5 * screen_width_f / 16 }, "Options");
        const quitGame_button = gui.guiButton(rl.Rectangle{ .height = button_height, .width = button_width, .x = button_x, .y = 6 * screen_width_f / 16 }, "Quit");

        if (levelSelect_button == 1) {
            currentMenu = menuType.levelSelect;
            boxes.canBoxesFall = true;
            return true;
        }
        if (levelEditor_button == 1) {
            currentMenu = menuType.levelEditor;
            player.clearPlayerAndMap();
            for (player.playerList.items) |p| p.deinit();
            player.playerList.clearAndFree();
            boxes.canBoxesFall = false;
            return false;
        }
        if (options_button == 1) {
            currentMenu = menuType.optionsMenu;
        }
        if (quitGame_button == 1) {
            rl.closeWindow();
        }
    }
    if (currentMenu == menuType.optionsMenu) {
        const width: f32 = @floatFromInt(game.boxSize * 4);
        const height: f32 = @floatFromInt(game.boxSize);
        const center: f32 = @floatFromInt(@divTrunc(rl.getScreenWidth(), 2));
        //RESOLUTION CONTROLS
        gui.guiSetStyle(gui.GuiControl.default, gui.GuiDefaultProperty.text_size, @divTrunc(rl.getScreenWidth(), 48));

        _ = gui.guiButton(rl.Rectangle{ .height = height, .width = width, .x = center - width / 2, .y = height * 6 }, resolutions[curRes]);
        const leftButton = gui.guiButton(rl.Rectangle{ .height = height / 2, .width = height / 2, .x = center - (width + height * 2) / 2, .y = height * 6 + height / 4 }, "<");
        const rightButton = gui.guiButton(rl.Rectangle{ .height = height / 2, .width = height / 2, .x = center + (width + height) / 2, .y = height * 6 + height / 4 }, ">");
        if (leftButton == 1 and curRes != 0) {
            curRes -= 1;
            game.setWindowSizeFromVector(resolutionVecs[curRes]);
        }
        if (rightButton == 1 and curRes != numResolutions - 1) {
            curRes += 1;
            game.setWindowSizeFromVector(resolutionVecs[curRes]);
        }
        gui.guiSetStyle(gui.GuiControl.default, gui.GuiDefaultProperty.text_size, @divTrunc(rl.getScreenWidth(), 64));
        //GO BACK BUTTON
        const backButton = gui.guiButton(rl.Rectangle{ .height = height / 2, .width = width / 2, .x = center - width / 4, .y = height * 7.5 }, "Go Back");
        if (backButton == 1) currentMenu = menuType.main;
    }
    if (currentMenu == menuType.levelSelect) {
        if (checkPause()) {
            return true;
        }
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
