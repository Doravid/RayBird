// raylib-zig (c) Nikolas Wipper 2023 :D
const rl = @import("raylib");
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
pub fn runGame() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    defer player.undoHistory.deinit();
    defer player.redoHistory.deinit();
    //To set config flags
    const myFlag = rl.ConfigFlags{
        .msaa_4x_hint = true,
    };

    rl.setConfigFlags(myFlag);

    rl.initWindow(screenWidth, screenHeight, "RayBird");
    rl.setTargetFPS(240);
    rl.setExitKey(rl.KeyboardKey.delete);

    var box = rl.loadImage("resources\\box.png");
    var plat = rl.loadImage("resources\\dirt.png");
    var fruit = rl.loadImage("resources\\fruit.png");
    var victory = rl.loadImage("resources\\victory.png");
    var del = rl.loadImage("resources\\delete.png");
    var spike = rl.loadImage("resources\\spike.png");

    rl.imageResize(&box, boxSize, boxSize);
    rl.imageResizeNN(&plat, boxSize, boxSize);
    rl.imageResize(&fruit, boxSize, boxSize);
    rl.imageResize(&victory, boxSize, boxSize);
    rl.imageResize(&del, boxSize, boxSize);
    rl.imageResize(&spike, boxSize, boxSize);

    const box_t = rl.loadTextureFromImage(box);
    const plat_t = rl.loadTextureFromImage(plat);
    const fruit_t = rl.loadTextureFromImage(fruit);
    const victory_t = rl.loadTextureFromImage(victory);
    const del_t = rl.loadTextureFromImage(del);
    const spike_t = rl.loadTextureFromImage(spike);

    defer rl.unloadImage(box);
    defer rl.unloadImage(plat);
    defer rl.unloadImage(fruit);
    defer rl.unloadImage(victory);
    defer rl.unloadImage(del);
    defer rl.unloadImage(spike);

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
        rl.drawRectangleGradientV(0, 0, screenWidth, screenHeight, Color.sky_blue, Color.orange);
        drawSmoothCircle(@divTrunc(screenWidth, 4), @divTrunc(screenHeight, 3), 130, 45, rl.Color.init(255, 250, 225, 230));

        if (inMenus) {
            inMenus = levelManager.loadMenu();
        } else {
            drawMap(plat_t, victory_t, fruit_t, spike_t);
            if (levelManager.currentMenu == levelManager.menuType.levelEditor) {
                const block: rl.Texture = switch (levelEditor.currentBlock) {
                    sol => plat_t,
                    frt => fruit_t,
                    bdy => box_t,
                    air => del_t,
                    vic => victory_t,
                    spk => spike_t,
                    else => undefined,
                };
                rl.drawTexturePro(block, rl.Rectangle{ .height = @floatFromInt(block.height), .width = @floatFromInt(block.width), .x = 0, .y = 0 }, rl.Rectangle{ .x = @as(f32, @floatFromInt(screenWidth - 80)), .y = 20, .height = 60, .width = 60 }, rl.Vector2{ .x = 0, .y = 0 }, 0, Color.white);
                rl.drawText("Current Block", screenWidth - 100, 85, 14, Color.black);
            }
            player.drawPlayer(box_t);
            inMenus = levelManager.checkPause();
        }
        rl.drawFPS(0, 0);
        drawWater();
        rl.drawTriangle(rl.Vector2{ .x = 0, .y = 0 }, rl.Vector2{ .x = 100, .y = 0 }, rl.Vector2{ .x = 50, .y = 100 }, rl.Color.yellow);
    }
}
pub fn drawSmoothCircle(x: i32, y: i32, radius: f32, segments: i32, color: rl.Color) void {
    const _x = @as(f32, @floatFromInt(x));
    const _y = @as(f32, @floatFromInt(y));

    const angleStep = 2.0 * std.math.pi / @as(f32, @floatFromInt(segments));
    const p0 = rl.Vector2{ .x = _x, .y = _y };

    var i: i32 = 0;
    while (i < segments) : (i += 1) {
        const angle1 = @as(f32, @floatFromInt(i)) * angleStep;
        const angle2 = @as(f32, @floatFromInt(i + 1)) * angleStep;

        const p1 = rl.Vector2{
            .x = _x + @cos(angle1) * radius,
            .y = _y + @sin(angle1) * radius,
        };

        const p2 = rl.Vector2{
            .x = _x + @cos(angle2) * radius,
            .y = _y + @sin(angle2) * radius,
        };

        // Draw triangle
        rl.drawTriangle(p2, p1, p0, color);
    }
}
//Draws all of the boxes in the map each frame.
fn drawMap(plat_t: rl.Texture, victory_t: rl.Texture, fruit_t: rl.Texture, spike_t: rl.Texture) void {
    for (player.mat16x9, 0..) |row, rIndex| {
        for (row, 0..) |element, cIndex| {
            const rw: i32 = @intCast(cIndex);
            const col: i32 = @intCast(rIndex);
            switch (element) {
                sol => rl.drawTexture(plat_t, boxSize * rw, col * boxSize, rl.Color.white),
                vic => rl.drawTexture(victory_t, boxSize * rw, col * boxSize, rl.Color.white),
                frt => rl.drawTexture(fruit_t, boxSize * rw, col * boxSize, rl.Color.white),
                spk => rl.drawTexture(spike_t, boxSize * rw, col * boxSize, rl.Color.white),
                else => undefined,
            }
        }
    }
}
fn drawWater() void {
    const time: f32 = @floatCast(rl.getTime() * 1.5);
    rl.drawLineBezier(rl.Vector2.init(0, @as(f32, @floatFromInt(screenHeight)) - std.math.cos(time + 0.3) * 30 - 40), rl.Vector2.init(@as(f32, @floatFromInt(screenWidth)) / 2, @as(f32, @floatFromInt(screenHeight)) - std.math.sin(time + 0.3) * 30 - 40), 70, Color.blue);
    rl.drawLineBezier(rl.Vector2.init(0, @as(f32, @floatFromInt(screenHeight)) - std.math.cos(time) * 20), rl.Vector2.init(@as(f32, @floatFromInt(screenWidth)) / 2, @as(f32, @floatFromInt(screenHeight)) - std.math.sin(time) * 20), 100, Color.dark_blue);

    rl.drawLineBezier(rl.Vector2.init(@as(f32, @floatFromInt(screenWidth)) / 2, @as(f32, @floatFromInt(screenHeight)) - std.math.sin(time + 0.3) * 30 - 40), rl.Vector2.init(@as(f32, @floatFromInt(screenWidth)), @as(f32, @floatFromInt(screenHeight)) - std.math.cos(time + 0.3) * 30 - 40), 70, Color.blue);
    rl.drawLineBezier(rl.Vector2.init(@as(f32, @floatFromInt(screenWidth)) / 2, @as(f32, @floatFromInt(screenHeight)) - std.math.sin(time) * 20), rl.Vector2.init(@as(f32, @floatFromInt(screenWidth)), @as(f32, @floatFromInt(screenHeight)) - std.math.cos(time) * 20), 100, Color.dark_blue);
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
    if (blk == air or blk == frt or blk == vic or blk == spk) {
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
