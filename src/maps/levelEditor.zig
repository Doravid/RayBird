const game = @import("../game.zig");
const boxes = @import("../boxes.zig");
const player = @import("../player.zig");
const rl = @import("raylib");
const gui = @import("raygui");
const std = @import("std");
const levelManager = @import("levelManager.zig");
const fs = std.fs;
const json = std.json;

const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const box = blockType.box;

pub var currentBlock: blockType = sol;
var waitingOnInput = false;

pub var curBoxGroupNumber: usize = 0;
pub var curPlayerGroupNumber: usize = 0;
var userInput: [64:0]u8 = undefined;
var view: bool = true;

pub fn loadLevelEditor() void {
    handleSaveInput();

    if (waitingOnInput) {
        drawSaveDialog();
    } else {
        handleMouseInput();
        handleScrollWheel();
        handleGroupSelection();
        handleTabKey();
    }
}

fn handleSaveInput() void {
    if (!waitingOnInput and (rl.isKeyDown(rl.KeyboardKey.left_control) and rl.isKeyDown(rl.KeyboardKey.s))) {
        waitingOnInput = true;
    }
}

fn handleTabKey() void {
    if (rl.isKeyPressed(rl.KeyboardKey.tab)) {
        if (player.playerList.items.len > 0) {
            player.currentPlayerIndex = (player.currentPlayerIndex + 1) % player.playerList.items.len;
        }
    }
}

fn handleMouseInput() void {
    if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
        const mousePos = rl.getMousePosition();
        const worldPos = rl.getScreenToWorld2D(mousePos, game.camera);

        const replacedBlock = game.getBlockAtPixelCoord(worldPos.x, worldPos.y);

        if (currentBlock != bdy and currentBlock != box) {
            game.setBlockAtPixelCoord(worldPos.x, worldPos.y, currentBlock);
        } else if (currentBlock == bdy and replacedBlock != bdy) {
            placePlayerBody(worldPos);
        } else if (currentBlock == box and replacedBlock != box) {
            placeBox(worldPos);
        }
    }
}

fn placePlayerBody(pos: rl.Vector2) void {
    const x: i32 = @intFromFloat(@floor(pos.x / @as(f32, @floatFromInt(game.boxSize))));
    const y: i32 = @intFromFloat(@floor(pos.y / @as(f32, @floatFromInt(game.boxSize))));

    ensureListSize(&player.playerList, player.currentPlayerIndex);

    var currentPlayer = &player.playerList.items[player.currentPlayerIndex];

    if (shouldPlaceBodySegment(currentPlayer, x, y)) {
        currentPlayer.insert(0, rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) }) catch |err| {
            std.debug.print("Failed to insert/app body: {}\n", .{err});
            return;
        };
        game.setBlockAtPixelCoord(pos.x, pos.y, currentBlock);
    }
}

fn shouldPlaceBodySegment(currentPlayer: *std.ArrayList(rl.Vector2), x: i32, y: i32) bool {
    if (currentPlayer.items.len == 0) return true;

    const lastX = @as(i32, @intFromFloat(currentPlayer.items[0].x));
    const lastY = @as(i32, @intFromFloat(currentPlayer.items[0].y));

    const dx = @abs(x - lastX);
    const dy = @abs(y - lastY);

    std.debug.print("(Click) x: {}, y: {}\n(last) x: {}, y: {}\n(delta) x: {}, y: {}", .{ x, y, lastX, lastY, dx, dy });

    return (dx == 1 and dy == 0) or (dy == 1 and dx == 0);
}

fn placeBox(pos: rl.Vector2) void {
    const x: i32 = @divTrunc(@as(i32, @intFromFloat(pos.x)), game.boxSize);
    const y: i32 = @divTrunc(@as(i32, @intFromFloat(pos.y)), game.boxSize);

    ensureListSize(&boxes.boxList, curBoxGroupNumber);

    var boxGroup: *std.ArrayList(rl.Vector2) = &boxes.boxList.items[curBoxGroupNumber];
    boxGroup.append(rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) }) catch |err| {
        std.debug.print("Failed to append to box: {}\n", .{err});
        return;
    };
    game.setBlockAtPixelCoord(pos.x, pos.y, currentBlock);
}

fn ensureListSize(list: anytype, index: usize) void {
    while (list.items.len <= index) {
        const newItem = std.ArrayList(rl.Vector2).init(std.heap.c_allocator);
        list.append(newItem) catch |err| {
            std.debug.print("Failed to append to list: {}\n", .{err});
            return;
        };
    }
}

fn drawSaveDialog() void {
    const screenWidth = @as(f32, @floatFromInt(rl.getScreenWidth()));
    const textBoxRect = rl.Rectangle{ .height = 1.25 * screenWidth / 16.0, .width = 4.0 * screenWidth / 16.0, .x = (screenWidth / 2.0) - 240.0, .y = 80 };

    const res = gui.guiTextInputBox(textBoxRect, "Save Level", "Please enter level name:", "Save;Cancel", &userInput, 64, &view);

    if (res == 1) {
        saveLevelData();
        waitingOnInput = false;
        clearUserInput();
    } else if (res == 2) {
        waitingOnInput = false;
        clearUserInput();
    }
}

fn saveLevelData() void {
    var tempBoxes = std.ArrayList([]rl.Vector2).init(std.heap.c_allocator);
    defer tempBoxes.deinit();

    for (boxes.boxList.items) |group| {
        tempBoxes.append(group.items) catch return;
    }

    var tempPlayers = std.ArrayList([]rl.Vector2).init(std.heap.c_allocator);
    defer tempPlayers.deinit();

    for (player.playerList.items) |group| {
        tempPlayers.append(group.items) catch return;
    }
    var iterator = levelManager.dynamic_map.iterator();
    const map_array = std.heap.c_allocator.alloc(levelManager.BlockDef, levelManager.dynamic_map.count()) catch return;

    var i: usize = 0;

    while (iterator.next()) |entry| {
        const block_def = levelManager.BlockDef{ .x = entry.key_ptr.*[0], .y = entry.key_ptr.*[1], .t = entry.value_ptr.* };
        map_array[i] = block_def;
        i += 1;
    }

    const levelData = levelManager.level{
        .map = map_array,
        .player = tempPlayers.items,
        .boxes = tempBoxes.items,
    };

    writeLevelToFile(levelData, userInput);
}

fn clearUserInput() void {
    @memset(&userInput, 0);
}

fn handleScrollWheel() void {
    const numBlocks: comptime_int = 7;
    const wheel = rl.getMouseWheelMove();

    if (wheel > 0) {
        currentBlock = @enumFromInt(@mod(@intFromEnum(currentBlock) + 1, numBlocks));
    } else if (wheel < 0) {
        var x = @intFromEnum(currentBlock) - 1;
        if (x < 0) x = numBlocks - 1;
        currentBlock = @enumFromInt(x);
    }
}

fn handleGroupSelection() void {
    if (currentBlock != bdy and currentBlock != box) return;

    const keyInt = @intFromEnum(rl.getKeyPressed());
    const zeroInt = @intFromEnum(rl.KeyboardKey.zero);

    if (keyInt >= zeroInt) {
        const key = keyInt - zeroInt;
        if (key >= 0 and key <= 9) {
            if (currentBlock == box) {
                curBoxGroupNumber = @intCast(key);
            } else {
                player.currentPlayerIndex = @intCast(key);
            }
        }
    }
}

fn writeLevelToFile(level1: levelManager.level, name: [64:0]u8) void {
    const allocator = std.heap.c_allocator;
    const name_slice = std.mem.sliceTo(&name, 0);
    const prefix = "resources/maps/";
    const suffix = ".json";

    const path = allocator.alloc(u8, prefix.len + name_slice.len + suffix.len) catch |err| {
        std.debug.print("Failed to allocate: {}\n", .{err});
        return;
    };
    defer allocator.free(path);

    std.mem.copyForwards(u8, path[0..], prefix);
    std.mem.copyForwards(u8, path[prefix.len..], name_slice);
    std.mem.copyForwards(u8, path[prefix.len + name_slice.len ..], suffix);

    const string = json.stringifyAlloc(allocator, level1, .{ .emit_strings_as_arrays = false }) catch |err| {
        std.debug.print("Failed to stringify: {}\n", .{err});
        return;
    };
    defer allocator.free(string);

    var file = fs.cwd().createFile(path, .{}) catch |err| {
        std.debug.print("Failed to createFile: {}\n", .{err});
        return;
    };
    defer file.close();

    _ = file.writeAll(string) catch |err| {
        std.debug.print("Failed to writeAll: {}\n", .{err});
        return;
    };
}
