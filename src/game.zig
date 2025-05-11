// raylib-zig (c) Nikolas Wipper 2023 :D
const rl = @import("raylib");
const std = @import("std");
const gui = @import("raygui");
const player = @import("player.zig");
const levelManager = @import("maps\\levelManager.zig");
const levelEditor = @import("maps\\levelEditor.zig");

pub const blockType = enum(i32) { sol = 0, bdy = 1, frt = 2, vic = 3, air = 4, spk = 5, null = -1 };
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const vic = blockType.vic;

const Color = rl.Color;
const KeyboardKey = rl.KeyboardKey;

pub const screenWidth = 1920;
pub const screenHeight = 1080;

pub var boxSize: i32 = screenWidth / 16;
pub fn runGame() !void {
    rl.initWindow(1920, 1080, "RayBird");

    rl.setTargetFPS(360);
    rl.setExitKey(rl.KeyboardKey.delete);

    var box = rl.loadImage("resources\\box.png");
    var plat = rl.loadImage("resources\\dirt.png");
    var fruit = rl.loadImage("resources\\fruit.png");
    var victory = rl.loadImage("resources\\victory.png");
    var del = rl.loadImage("resources\\delete.png");
    var spike = rl.loadImage("resources\\spike.png");

    var cloud = rl.loadImage("resources\\cloud1.png");

    rl.imageResize(&box, boxSize, boxSize);
    rl.imageResizeNN(&plat, boxSize, boxSize);
    rl.imageResize(&fruit, boxSize, boxSize);
    rl.imageResize(&victory, boxSize, boxSize);
    rl.imageResize(&del, boxSize, boxSize);
    rl.imageResize(&spike, boxSize, boxSize);
    rl.imageResize(&cloud, @intFromFloat(@as(f32, @floatFromInt(boxSize)) * 5), boxSize * 3);

    const box_t = rl.loadTextureFromImage(box);
    const plat_t = rl.loadTextureFromImage(plat);
    const fruit_t = rl.loadTextureFromImage(fruit);
    const victory_t = rl.loadTextureFromImage(victory);
    const del_t = rl.loadTextureFromImage(del);
    const spike_t = rl.loadTextureFromImage(spike);
    const cloud_t = rl.loadTextureFromImage(cloud);

    defer rl.unloadImage(box);
    defer rl.unloadImage(plat);
    defer rl.unloadImage(fruit);
    defer rl.unloadImage(victory);
    defer rl.unloadImage(del);
    defer rl.unloadImage(spike);
    defer rl.unloadImage(cloud);

    defer rl.closeWindow(); // Close window and OpenGL context
    var inMenus: bool = true;
    //--------------------------------------------------------------------------------------
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or DEL key

        if (rl.getKeyPressed() == rl.KeyboardKey.h) {
            rl.setWindowSize(2560, 1440);
            boxSize = @divExact(rl.getScreenWidth(), 16);
        }
        // Update
        player.updateGravity();
        player.updatePos();
        fullScreen();
        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        //Clear and draw background.
        rl.clearBackground(rl.Color.white);
        drawSky(cloud_t);
        if (inMenus) {
            inMenus = levelManager.loadMenu();
            _ = levelManager.checkPause();
        } else {
            drawMap(plat_t, victory_t, fruit_t, spike_t, box_t);
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
        drawWater();
    }
}
fn drawSky(cloud_t: rl.Texture2D) void {
    const time: f32 = @floatCast(rl.getTime());
    const modTime: f64 = (std.math.mod(f64, time / 110, 1)) catch |err| {
        std.debug.print("{}", .{err});
        return;
    };
    const modTime2: f64 = (std.math.mod(f64, (time + 35) / 80, 1)) catch |err| {
        std.debug.print("{}", .{err});
        return;
    };
    const xCloud: i32 = @as(i32, @intFromFloat(modTime * 1.4 * @as(f32, @floatFromInt(screenWidth)))) - boxSize * 5;
    const xCloud2: i32 = @as(i32, @intFromFloat(modTime2 * 1.4 * @as(f32, @floatFromInt(screenWidth)))) - boxSize * 5;
    const x = @as(f32, @floatFromInt(screenWidth)) * @abs(std.math.sin(time / 500));
    //Draw the Sky Background
    rl.drawRectangleGradientV(0, 0, screenWidth, screenHeight, Color.sky_blue, Color.orange);
    //Draw the Sun
    drawSmoothCircle(x, @floatFromInt(@divTrunc(screenHeight, 3)), 150, 50, rl.Color.init(255, 245, 230, 255));
    //draw the Clouds
    rl.drawTexture(cloud_t, xCloud, boxSize, rl.Color.init(255, 250, 245, 230));
    rl.drawTexture(cloud_t, screenWidth - xCloud - boxSize * 4, @intFromFloat(@as(f32, @floatFromInt(boxSize)) * 2.5), rl.Color.init(255, 250, 245, 230));
    rl.drawTexture(cloud_t, xCloud2, boxSize * 2, rl.Color.init(255, 250, 245, 230));
}
pub fn drawSmoothCircle(x: f32, y: f32, radius: f32, segments: i32, color: rl.Color) void {
    const angleStep = 2.0 * std.math.pi / @as(f32, @floatFromInt(segments));
    const p0 = rl.Vector2{ .x = x, .y = y };

    var i: i32 = 0;
    while (i < segments) : (i += 1) {
        const angle1 = @as(f32, @floatFromInt(i)) * angleStep;
        const angle2 = @as(f32, @floatFromInt(i + 1)) * angleStep;

        const p1 = rl.Vector2{
            .x = x + @cos(angle1) * radius,
            .y = y + @sin(angle1) * radius,
        };

        const p2 = rl.Vector2{
            .x = x + @cos(angle2) * radius,
            .y = y + @sin(angle2) * radius,
        };

        // Draw triangle
        rl.drawTriangle(p2, p1, p0, color);
    }
}
//Draws all of the boxes in the map each frame.
fn drawMap(plat_t: rl.Texture, victory_t: rl.Texture, fruit_t: rl.Texture, spike_t: rl.Texture, box_t: rl.Texture) void {
    for (player.mat16x9, 0..) |row, rIndex| {
        for (row, 0..) |element, cIndex| {
            const rw: i32 = @intCast(cIndex);
            const col: i32 = @intCast(rIndex);
            switch (element) {
                sol => rl.drawTexture(plat_t, boxSize * rw, col * boxSize, rl.Color.white),
                vic => rl.drawTexture(victory_t, boxSize * rw, col * boxSize, rl.Color.white),
                frt => rl.drawTexture(fruit_t, boxSize * rw, col * boxSize, rl.Color.white),
                spk => rl.drawTexture(spike_t, boxSize * rw, col * boxSize, rl.Color.white),
                bdy => rl.drawTexture(box_t, boxSize * rw, col * boxSize, rl.Color.white),
                else => undefined,
            }
        }
    }
}
fn drawTexture(texture: rl.Texture, posX: i32, posY: i32, tint: rl.Color) void {}
fn drawWater() void {
    const time: f32 = @floatCast(rl.getTime() * 1.35);
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
pub fn posMoveable(x: f32, y: f32) bool {
    const blk = getBlockAt(x, y);
    if (blk == air or blk == frt or blk == vic or blk == spk) {
        return true;
    }
    return false;
}
//Returns the block at a given x,y coordinate (in pixel coordinates)
pub fn getBlockAt(x: f32, y: f32) blockType {
    const new_x = x / @as(f32, @floatFromInt(boxSize));
    const new_y = y / @as(f32, @floatFromInt(boxSize));
    if (new_x >= 16 or new_y >= 9 or new_x < 0 or new_y < 0) {
        std.debug.print("{}, {} is out of bounds\n", .{ x, y });
        return blockType.null;
    }
    return player.mat16x9[@intFromFloat(new_y)][@intFromFloat(new_x)];
}
//Uses screen coords (not box Coords, which are different and used by the mat16x9 array)
pub fn setBlockAt(x: f32, y: f32, block: blockType) void {
    const new_x = x / @as(f32, @floatFromInt(boxSize));
    const new_y = y / @as(f32, @floatFromInt(boxSize));
    if (new_x >= 16 or new_y >= 9 or new_x < 0 or new_y < 0) {
        std.debug.print("Out of bounds\n", .{});
        return;
    }
    player.mat16x9[@intFromFloat(new_y)][@intFromFloat(new_x)] = block;
}
