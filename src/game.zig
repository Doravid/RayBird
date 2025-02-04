// raylib-zig (c) Nikolas Wipper 2023 :D
const rl = @import("raylib");
const gui = @import("raygui");
const std = @import("std");
const player = @import("player.zig");
const levelManager = @import("maps\\levelManager.zig");
const levelEditor = @import("maps\\levelEditor.zig");

const windowedWidth = 1920;
const windowedHeight = 1080;

pub const blockType = enum(i32) { sol = 0, bdy = 1, frt = 2, vic = 3, air = 4, spk = 5, null = -1 };
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const vic = blockType.vic;

const Color = rl.Color;
const KeyboardKey = rl.KeyboardKey;

pub var screenWidth: i32 = windowedWidth;
pub var screenHeight: i32 = windowedHeight;

pub var boxSize: i32 = 120;
pub fn runGame() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    defer player.undoHistory.deinit();
    defer player.redoHistory.deinit();
    rl.initWindow(screenWidth, screenHeight, "RayBird");
    rl.setTargetFPS(240);
    rl.setExitKey(rl.KeyboardKey.delete);

    var box = rl.loadImage("resources\\box.png");
    var plat = rl.loadImage("resources\\dirt.png");
    var fruit = rl.loadImage("resources\\fruit.png");
    var victory = rl.loadImage("resources\\victory.png");
    var del = rl.loadImage("resources\\delete.png");

    rl.imageResize(&box, boxSize, boxSize);
    rl.imageResizeNN(&plat, boxSize, boxSize);
    rl.imageResize(&fruit, boxSize, boxSize);
    rl.imageResize(&victory, boxSize, boxSize);
    rl.imageResize(&del, boxSize, boxSize);

    const box_t = rl.loadTextureFromImage(box);
    const plat_t = rl.loadTextureFromImage(plat);
    const fruit_t = rl.loadTextureFromImage(fruit);
    const victory_t = rl.loadTextureFromImage(victory);
    const del_t = rl.loadTextureFromImage(del);

    player.initPlayer();

    defer rl.unloadImage(box);
    defer rl.unloadImage(plat);
    defer rl.unloadImage(fruit);

    defer rl.closeWindow(); // Close window and OpenGL context
    var inMenus: bool = true;
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or DEL key
        // Update
        player.updateGravity();
        player.updatePos();
        fullScreen();
        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        //Clear and draw background.
        rl.clearBackground(rl.Color.white);
        rl.drawRectangleGradientV(0, 0, screenWidth, screenHeight, Color.ray_white, Color.sky_blue);

        if (inMenus) {
            inMenus = levelManager.loadMenu();
        } else {
            drawMap(plat_t, victory_t);
            drawFruit(fruit_t);
            inMenus = levelManager.checkPause();
            if (levelManager.currentMenu == levelManager.menuType.levelEditor) {
                const block: rl.Texture = switch (levelEditor.currentBlock) {
                    sol => plat_t,
                    frt => fruit_t,
                    bdy => box_t,
                    air => del_t,
                    vic => victory_t,
                    else => undefined,
                };
                rl.drawTexturePro(block, rl.Rectangle{ .height = @floatFromInt(block.height), .width = @floatFromInt(block.width), .x = 0, .y = 0 }, rl.Rectangle{ .x = @as(f32, @floatFromInt(screenWidth - 80)), .y = 20, .height = 60, .width = 60 }, rl.Vector2{ .x = 0, .y = 0 }, 0, Color.white);
                rl.drawText("Current Block", screenWidth - 100, 85, 14, Color.black);
            }
            checkLevelChange();
            player.drawPlayer(box_t);
        }
        rl.drawFPS(0, 0);
        //----------------------------------------------------------------------------------
    }
}
//Draws all of the boxes in the map each frame.
fn drawMap(plat_t: rl.Texture, victory_t: rl.Texture) void {
    for (player.mat16x9, 0..) |row, rIndex| {
        for (row, 0..) |element, cIndex| {
            if (element == sol) {
                const rw: i32 = @intCast(cIndex);
                const col: i32 = @intCast(rIndex);
                rl.drawTexture(plat_t, boxSize * rw, col * boxSize, rl.Color.white);
            }
            if (element == vic) {
                const rw: i32 = @intCast(cIndex);
                const col: i32 = @intCast(rIndex);
                rl.drawTexture(victory_t, boxSize * rw, col * boxSize, rl.Color.white);
            }
        }
    }
}
fn drawFruit(texture: rl.Texture) void {
    for (player.mat16x9, 0..) |row, rIndex| {
        for (row, 0..) |element, cIndex| {
            if (element == blockType.frt) {
                const rw: i32 = @intCast(cIndex);
                const col: i32 = @intCast(rIndex);
                rl.drawTexture(texture, boxSize * rw, col * boxSize, rl.Color.white);
            }
        }
    }
}

fn fullScreen() void {
    if (rl.isKeyPressed(rl.KeyboardKey.f11)) {
        rl.toggleFullscreen();
        return;
    }
}

//Cehcks if a given position is a valid location for the player to move.
pub fn posMoveable(x: i32, y: i32) bool {
    const blk = getBlockAt(x, y);
    if (blk == air or blk == frt or blk == vic) {
        return true;
    }
    return false;
}
//Returns the block at a given x,y coordinate (in pixel coordinates)
pub fn getBlockAt(x: i32, y: i32) blockType {
    const new_x = @divTrunc(x, boxSize);
    const new_y = @divTrunc(y, boxSize);
    if (new_x >= 16 or new_y >= 9 or new_x < 0 or new_y < 0) {
        std.debug.print("{}, {} is out of bounds\n", .{ x, y });
        return blockType.null;
    }
    return player.mat16x9[@intCast(new_y)][@intCast(new_x)];
}
//Uses screen coords (not box Coords, which are different and used by the mat16x9 array)
pub fn setBlockAt(x: i32, y: i32, block: blockType) void {
    const new_x = @divTrunc(x, boxSize);
    const new_y = @divTrunc(y, boxSize);
    if (new_x >= 16 or new_y >= 9 or new_x < 0 or new_y < 0) {
        std.debug.print("Out of bounds\n", .{});
        return;
    }
    player.mat16x9[@intCast(new_y)][@intCast(new_x)] = block;
}

fn checkLevelChange() void {
    const x: i16 = @intCast(@intFromEnum(rl.getKeyPressed()));
    if (x < 49 or x > 57) return;
    levelManager.setLevel(@intCast(x - 49));
}
