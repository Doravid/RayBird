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

pub var boxSize: i32 = 1920 / 16;
pub fn runGame() !void {
    const box = rl.loadImage("resources\\box.png");
    const plat = rl.loadImage("resources\\dirt.png");
    const fruit = rl.loadImage("resources\\fruit.png");
    const victory = rl.loadImage("resources\\victory.png");
    const del = rl.loadImage("resources\\delete.png");
    const spike = rl.loadImage("resources\\spike.png");
    const cloud = rl.loadImage("resources\\cloud1.png");

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
            if (rl.getScreenHeight() == 1080) {
                rl.setWindowSize(2560, 1440);
            } else {
                rl.setWindowSize(1920, 1080);
            }
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
        rl.endShaderMode();
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
                rl.drawTexturePro(block, rl.Rectangle{ .height = @floatFromInt(block.height), .width = @floatFromInt(block.width), .x = 0, .y = 0 }, rl.Rectangle{ .x = @as(f32, @floatFromInt(rl.getScreenWidth() - @divTrunc(boxSize, 4) * 3)), .y = @as(f32, @floatFromInt(boxSize)) / 4, .height = @as(f32, @floatFromInt(boxSize)) / 2, .width = @as(f32, @floatFromInt(boxSize)) / 2 }, rl.Vector2{ .x = 0, .y = 0 }, 0, Color.white);
                rl.drawText("Current Block", rl.getScreenWidth() - boxSize, @divTrunc(boxSize, 7) * 6, @divTrunc(boxSize, 8), Color.black);
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
    const xCloud: i32 = @as(i32, @intFromFloat(modTime * 1.4 * @as(f32, @floatFromInt(rl.getScreenWidth())))) - boxSize * 5;
    const xCloud2: i32 = @as(i32, @intFromFloat(modTime2 * 1.3 * @as(f32, @floatFromInt(rl.getScreenWidth())))) - boxSize * 5;
    const x = @as(f32, @floatFromInt(rl.getScreenWidth())) * @abs(std.math.sin(time / 500));
    //Draw the Sky Background
    rl.drawRectangleGradientV(0, 0, rl.getScreenWidth(), rl.getScreenHeight(), Color.sky_blue, Color.orange);
    //Draw the Sun
    drawSmoothCircle(x, @floatFromInt(@divTrunc(rl.getScreenHeight(), 3)), 150, 50, rl.Color.init(255, 245, 230, 255));
    //draw the Clouds
    drawTextureNew(cloud_t, xCloud, boxSize, rl.Color.init(255, 250, 245, 230), 0.5);
    rl.drawTexture(cloud_t, rl.getScreenWidth() - xCloud - boxSize * 4, @intFromFloat(@as(f32, @floatFromInt(boxSize)) * 2.5), rl.Color.init(255, 250, 245, 230));
    drawTextureNew(cloud_t, xCloud2, boxSize * 2, rl.Color.init(255, 250, 245, 230), 0.8);
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
                sol => drawTexture(plat_t, boxSize * rw, col * boxSize, rl.Color.white),
                vic => drawTexture(victory_t, boxSize * rw, col * boxSize, rl.Color.white),
                frt => drawTexture(fruit_t, boxSize * rw, col * boxSize, rl.Color.white),
                spk => drawTexture(spike_t, boxSize * rw, col * boxSize, rl.Color.white),
                bdy => drawTexture(box_t, boxSize * rw, col * boxSize, rl.Color.white),
                else => undefined,
            }
        }
    }
}
pub fn drawTexture(texture: rl.Texture, posX: i32, posY: i32, tint: rl.Color) void {
    const source = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(texture.width), .height = @floatFromInt(texture.height) };
    const dest = rl.Rectangle{ .x = @floatFromInt(posX), .y = @floatFromInt(posY), .width = @floatFromInt(boxSize), .height = @floatFromInt(boxSize) };
    const origin = rl.Vector2{ .x = 0, .y = 0 };
    const rotation = 0.0;
    rl.drawTexturePro(texture, source, dest, origin, rotation, tint);
}
pub fn drawTextureNew(texture: rl.Texture, posX: i32, posY: i32, tint: rl.Color, scaling: f32) void {
    const source = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(texture.width), .height = @floatFromInt(texture.height) };
    const dest = rl.Rectangle{ .x = @floatFromInt(posX), .y = @floatFromInt(posY), .width = @as(f32, @floatFromInt(texture.width)) * (scaling), .height = @as(f32, @floatFromInt(texture.height)) * scaling };
    const origin = rl.Vector2{ .x = 0, .y = 0 };
    const rotation = 0.0;
    rl.drawTexturePro(texture, source, dest, origin, rotation, tint);
}

fn drawWater() void {
    const time: f32 = @floatCast(rl.getTime() * 1.35);

    rl.drawLineBezier(rl.Vector2.init(0, @as(f32, @floatFromInt(rl.getScreenHeight())) - std.math.cos(time + 0.3) * 30 - 40), rl.Vector2.init(@as(f32, @floatFromInt(rl.getScreenWidth())) / 2, @as(f32, @floatFromInt(rl.getScreenHeight())) - std.math.sin(time + 0.3) * 30 - 40), 70, Color.blue);
    rl.drawLineBezier(rl.Vector2.init(0, @as(f32, @floatFromInt(rl.getScreenHeight())) - std.math.cos(time) * 20), rl.Vector2.init(@as(f32, @floatFromInt(rl.getScreenWidth())) / 2, @as(f32, @floatFromInt(rl.getScreenHeight())) - std.math.sin(time) * 20), 100, Color.dark_blue);

    rl.drawLineBezier(rl.Vector2.init(@as(f32, @floatFromInt(rl.getScreenWidth())) / 2, @as(f32, @floatFromInt(rl.getScreenHeight())) - std.math.sin(time + 0.3) * 30 - 40), rl.Vector2.init(@as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight())) - std.math.cos(time + 0.3) * 30 - 40), 70, Color.blue);
    rl.drawLineBezier(rl.Vector2.init(@as(f32, @floatFromInt(rl.getScreenWidth())) / 2, @as(f32, @floatFromInt(rl.getScreenHeight())) - std.math.sin(time) * 20), rl.Vector2.init(@as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight())) - std.math.cos(time) * 20), 100, Color.dark_blue);
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
pub fn setWindowSizeFromVector(ScreenSize: rl.Vector2) void {
    rl.setWindowSize(@intFromFloat(ScreenSize.x), @intFromFloat(ScreenSize.y));
    boxSize = @divExact(rl.getScreenWidth(), 16);
    gui.guiSetStyle(gui.GuiControl.default, gui.GuiDefaultProperty.text_size, @divTrunc(rl.getScreenWidth(), 64));
}
