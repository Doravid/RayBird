// raylib-zig (c) Nikolas Wipper 2023 :D
const rl = @import("raylib");
const std = @import("std");
const player = @import("player.zig");
const levelManager = @import("maps\\levelManager.zig");

const windowedWidth = 1920;
const windowedHeight = 1080;

pub const blockType = enum { sol, air, spk, bdy, null, frt };
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const KeyboardKey = rl.KeyboardKey;
const Color = rl.Color;

pub var screenWidth: i32 = windowedWidth;
pub var screenHeight: i32 = windowedHeight;
pub var boxSize: i32 = 120;
const pos = player.pos;

pub fn runGame() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    defer player.undoHistory.deinit();
    defer player.redoHistory.deinit();

    rl.initWindow(screenWidth, screenHeight, "Boxes");
    rl.setTargetFPS(240); // Set our game to run at 60 frames-per-second

    var box = rl.loadImage("resources\\box.png");
    var plat = rl.loadImage("resources\\dirt.png");
    var fruit = rl.loadImage("resources\\fruit.png");

    rl.imageResize(&box, boxSize, boxSize);
    rl.imageResizeNN(&plat, boxSize, boxSize);
    rl.imageResize(&fruit, boxSize, boxSize);

    const box_t = rl.loadTextureFromImage(box);
    const plat_t = rl.loadTextureFromImage(plat);
    const fruit_t = rl.loadTextureFromImage(fruit);
    player.initPlayer();
    defer rl.unloadImage(box);
    defer rl.unloadImage(plat);
    defer rl.unloadImage(fruit);

    defer rl.closeWindow(); // Close window and OpenGL context

    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        player.updateGravity();
        player.updatePos();
        fullScreen();
        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
        rl.drawRectangleGradientV(0, 0, screenWidth, screenHeight, Color.ray_white, Color.sky_blue);
        drawMap(plat_t);
        drawFruit(fruit_t);
        player.drawPlayer(box_t);

        rl.drawFPS(0, 0);
        //----------------------------------------------------------------------------------
    }
}
//Draws all of the boxes in the map each frame.
fn drawMap(plat_t: rl.Texture) void {
    for (player.mat16x9, 0..) |row, rIndex| {
        for (row, 0..) |element, cIndex| {
            if (element == sol) {
                const rw: i32 = @intCast(cIndex);
                const col: i32 = @intCast(rIndex);
                rl.drawTexture(plat_t, boxSize * rw, col * boxSize, rl.Color.white);
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
    if (rl.isKeyPressed(rl.KeyboardKey.key_f11)) {
        rl.toggleFullscreen();
        return;
    }
}

//Cehcks if a given position is a valid location for the player to move.
pub fn posMoveable(x: i32, y: i32) bool {
    if (getBlockAt(x, y) == air or getBlockAt(x, y) == blockType.frt) {
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
    const x: i16 = @intFromEnum(rl.getKeyPressed());
    if (x < 49 or x > 57) return;
    levelManager.setLevel(x);
}
