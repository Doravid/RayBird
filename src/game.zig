// raylib-zig (c) Nikolas Wipper 2023 :D
const rl = @import("raylib");
const std = @import("std");
const gui = @import("raygui");
const player = @import("player.zig");
const boxes = @import("boxes.zig");
const levelManager = @import("maps/levelManager.zig");
const levelEditor = @import("maps/levelEditor.zig");
const builtin = @import("builtin");

pub const blockType = enum(i32) { sol = 0, bdy = 1, frt = 2, vic = 3, air = 4, spk = 5, box = 6, null = -1 };
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const vic = blockType.vic;
const box = blockType.box;
const Color = rl.Color;
const KeyboardKey = rl.KeyboardKey;
var backgroundTexture: rl.RenderTexture = undefined;
var waterTexture: rl.RenderTexture = undefined;
// pub var sounds = std.ArrayList(rl.Sound).init(std.heap.c_allocator);

pub var body_textures: [4]rl.Texture2D = undefined;
var bloomShader: rl.Shader = undefined;
var pixelShader: rl.Shader = undefined;
var finePixelShader: rl.Shader = undefined;
var sizeLoc: i32 = undefined;
var renderWidthLoc: i32 = undefined;
var renderHeightLoc: i32 = undefined;

pub var boxSize: i32 = 1920 / 16;
pub fn runGame() !void {
    // try sounds.append(rl.loadSound("resources/audio/move.mp3"));
    // try sounds.append(rl.loadSound("resources/audio/move2.mp3"));

    const move = rl.loadImage("resources/box.png");
    const plat = rl.loadImage("resources/dirt1.png");
    const plat2 = rl.loadImage("resources/dirt2.png");
    const grass = rl.loadImage("resources/grass.png");
    const fruit = rl.loadImage("resources/fruit.png");
    const victory = rl.loadImage("resources/victory.png");
    const del = rl.loadImage("resources/delete.png");
    const spike = rl.loadImage("resources/spike.png");
    const cloud = rl.loadImage("resources/cloud1.png");

    const body1 = rl.loadImage("resources/head.png");
    const body2 = rl.loadImage("resources/body1.png");
    const body3 = rl.loadImage("resources/body2.png");
    const body4 = rl.loadImage("resources/body4.png");

    bloomShader = rl.loadShader(null, "resources/shaders/bloom.fs");
    pixelShader = rl.loadShader(null, "resources/shaders/pixel.fs");
    finePixelShader = rl.loadShader(null, "resources/shaders/pixel_fine.fs");

    sizeLoc = rl.getShaderLocation(pixelShader, "size");
    renderWidthLoc = rl.getShaderLocation(pixelShader, "renderWidth");
    renderHeightLoc = rl.getShaderLocation(pixelShader, "renderHeight");

    backgroundTexture = rl.loadRenderTexture(1920, 1080);
    waterTexture = rl.loadRenderTexture(1920, 1080);

    const move_t = rl.loadTextureFromImage(move);
    const plat_t = rl.loadTextureFromImage(plat);
    const plat2_t = rl.loadTextureFromImage(plat2);
    const grass_t = rl.loadTextureFromImage(grass);
    const fruit_t = rl.loadTextureFromImage(fruit);
    const victory_t = rl.loadTextureFromImage(victory);
    const del_t = rl.loadTextureFromImage(del);
    const spike_t = rl.loadTextureFromImage(spike);
    const cloud_t = rl.loadTextureFromImage(cloud);

    const body1_t = rl.loadTextureFromImage(body1);
    const body2_t = rl.loadTextureFromImage(body2);
    const body3_t = rl.loadTextureFromImage(body3);
    const body4_t = rl.loadTextureFromImage(body4);

    body_textures = [_]rl.Texture2D{ body1_t, body2_t, body3_t, body4_t };

    defer rl.unloadImage(move);
    defer rl.unloadImage(plat);
    defer rl.unloadImage(plat2);
    defer rl.unloadImage(fruit);
    defer rl.unloadImage(victory);
    defer rl.unloadImage(del);
    defer rl.unloadImage(spike);
    defer rl.unloadImage(cloud);
    defer rl.unloadImage(grass);

    defer rl.unloadImage(body1);
    defer rl.unloadImage(body2);
    defer rl.unloadImage(body3);
    defer rl.unloadImage(body4);

    defer rl.closeWindow(); // Close window and OpenGL context
    var inMenus: bool = true;
    //--------------------------------------------------------------------------------------
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or DEL key
        // Update
        player.updateGravity();
        boxes.updateBoxGravity();
        player.updatePos();
        fullScreen();

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        //Clear and draw background.
        rl.clearBackground(rl.Color.white);
        drawSky(cloud_t);

        if (inMenus) {
            drawWater();

            inMenus = levelManager.loadMenu();
        } else {
            drawMap(plat_t, plat2_t, victory_t, fruit_t, spike_t, grass_t);
            if (levelManager.currentMenu == levelManager.menuType.levelEditor) {
                const block: rl.Texture = switch (levelEditor.currentBlock) {
                    sol => plat_t,
                    frt => fruit_t,
                    bdy => body_textures[0],
                    air => del_t,
                    vic => victory_t,
                    spk => spike_t,
                    box => move_t,
                    else => undefined,
                };
                rl.drawTexturePro(block, rl.Rectangle{ .height = @floatFromInt(block.height), .width = @floatFromInt(block.width), .x = 0, .y = 0 }, rl.Rectangle{ .x = @as(f32, @floatFromInt(rl.getScreenWidth() - @divTrunc(boxSize, 4) * 3)), .y = @as(f32, @floatFromInt(boxSize)) / 4, .height = @as(f32, @floatFromInt(boxSize)) / 2, .width = @as(f32, @floatFromInt(boxSize)) / 2 }, rl.Vector2{ .x = 0, .y = 0 }, 0, Color.white);
                rl.drawText("Current Block", rl.getScreenWidth() - boxSize, @divTrunc(boxSize, 7) * 6, @divTrunc(boxSize, 8), Color.black);
                drawWater();
            }
            player.drawPlayer(&body_textures, null);
            boxes.drawBoxes(move_t);
            inMenus = levelManager.checkPause();
            drawWater();
        }
        rl.drawFPS(2, 2);
    }
}
fn drawSky(cloud_t: rl.Texture2D) void {
    const time: f32 = @floatCast(rl.getTime());
    const modTime: f64 = (std.math.mod(f64, time / 70, 1.5)) catch |err| {
        std.debug.print("{}", .{err});
        return;
    };
    const modTime2: f64 = (std.math.mod(f64, (time) / 80, 2.5)) catch |err| {
        std.debug.print("{}", .{err});
        return;
    };
    const xCloud: i32 = @as(i32, @intFromFloat(modTime * 1.6 * @as(f32, @floatFromInt(boxSize * 10)))) - boxSize * 5;
    const xCloud2: i32 = @as(i32, @intFromFloat(modTime2 * 1.3 * @as(f32, @floatFromInt(boxSize * 10)))) - boxSize * 14;
    const x = @as(f32, @floatFromInt(rl.getScreenWidth())) * @abs(std.math.sin(time / 500));

    //RENDER THE BACKGROUND TO A TEXTURE
    rl.beginTextureMode(backgroundTexture);
    rl.clearBackground(rl.Color.init(0, 0, 0, 0));

    //SKY AND SUN
    rl.drawRectangleGradientV(0, 0, rl.getScreenWidth(), rl.getScreenHeight(), Color.sky_blue, Color.orange);
    drawSmoothCircle(x, @floatFromInt(boxSize * 4), @floatFromInt(boxSize * 2), 50, rl.Color.init(250, 195, 190, 255));

    //CLOUDS
    drawTextureNew(cloud_t, xCloud, boxSize, rl.Color.init(255, 250, 245, 210), 0.5);
    drawTextureNew(cloud_t, rl.getScreenWidth() - xCloud - boxSize * 4, @intFromFloat(@as(f32, @floatFromInt(boxSize)) * 2.5), rl.Color.init(255, 250, 245, 210), 0.45);
    drawTextureNew(cloud_t, xCloud2, boxSize * 2, rl.Color.init(255, 250, 245, 210), 0.8);
    drawTextureNew(cloud_t, rl.getScreenWidth() - xCloud2 - boxSize * 4, @intFromFloat(@as(f32, @floatFromInt(boxSize)) * 2.5 + std.math.sin(time / 10) * @as(f32, @floatFromInt(boxSize)) / 2), rl.Color.init(255, 250, 245, 210), 0.7);

    rl.endTextureMode();

    const resolution = [2]f32{ @floatFromInt(rl.getScreenWidth()), @floatFromInt(rl.getScreenHeight()) };
    rl.setShaderValue(pixelShader, sizeLoc, &resolution, rl.ShaderUniformDataType.vec2);
    rl.setShaderValue(pixelShader, renderWidthLoc, &@as(f32, @floatFromInt(rl.getScreenWidth())), rl.ShaderUniformDataType.float);
    rl.setShaderValue(pixelShader, renderHeightLoc, &@as(f32, @floatFromInt(rl.getScreenHeight())), rl.ShaderUniformDataType.float);

    //RENDER THE TEXTURE WITH THE SHADER
    if (builtin.target.os.tag != .emscripten) {
        rl.beginShaderMode(pixelShader);
    }
    rl.drawTextureRec(backgroundTexture.texture, rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(backgroundTexture.texture.width), .height = -@as(f32, @floatFromInt(backgroundTexture.texture.height)) }, rl.Vector2{ .x = 0, .y = 0 }, rl.Color.white);
    rl.endShaderMode();
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
fn drawMap(plat_t: rl.Texture, plat2_t: rl.Texture, victory_t: rl.Texture, fruit_t: rl.Texture, spike_t: rl.Texture, grass_t: rl.Texture) void {
    for (levelManager.mat16x9, 0..) |row, rIndex| {
        for (row, 0..) |element, cIndex| {
            const rw: i32 = @intCast(cIndex);
            const col: i32 = @intCast(rIndex);
            switch (element) {
                sol => drawDirt(grass_t, plat_t, plat2_t, boxSize * rw, col * boxSize, rl.Color.white),
                vic => drawTexture(victory_t, boxSize * rw, col * boxSize, rl.Color.white),
                frt => drawFruit(fruit_t, boxSize * rw, col * boxSize),
                spk => drawTexture(spike_t, boxSize * rw, col * boxSize, rl.Color.white),
                // box => drawTexture(move_t, boxSize * rw, col * boxSize, rl.Color.white),
                else => undefined,
            }
        }
    }
}
fn drawFruit(fruit_t: rl.Texture, posX: i32, posY: i32) void {
    const time: f32 = @floatCast(rl.getTime());
    const sinTime = std.math.sin(time);
    const offset: i32 = @intFromFloat((sinTime * @as(f32, @floatFromInt(boxSize))) * 0.06);
    drawTexture(fruit_t, posX, posY + offset, rl.Color.white);
}
fn drawDirt(grass_t: rl.Texture, plat_t: rl.Texture, plat2_t: rl.Texture, posX: i32, posY: i32, color: rl.Color) void {
    if (getBlockAt(@floatFromInt(posX), @floatFromInt(posY - boxSize)) != sol) {
        drawTexture(grass_t, posX, posY, color);
    } else {
        var hash = @as(u32, @bitCast(posX));
        hash = hash ^ (@as(u32, @bitCast(posY)) << 16);
        hash = hash ^ (hash >> 13);
        hash = hash *% 0x5bd1e995;
        hash = hash ^ (hash >> 15);
        hash = hash *% 0x27d4eb2d;
        hash = hash ^ (hash >> 16);
        const random_value = hash % 100;

        if (random_value < 50) {
            drawTexture(plat2_t, posX, posY, color);
        } else {
            drawTexture(plat_t, posX, posY, color);
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
    const newScaling: f32 = scaling * @as(f32, @floatFromInt(boxSize)) / 100;
    const source = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(texture.width), .height = @floatFromInt(texture.height) };
    const dest = rl.Rectangle{ .x = @floatFromInt(posX), .y = @floatFromInt(posY), .width = @as(f32, @floatFromInt(texture.width)) * (newScaling), .height = @as(f32, @floatFromInt(texture.height)) * newScaling };
    const origin = rl.Vector2{ .x = 0, .y = 0 };
    const rotation = 0.0;
    rl.drawTexturePro(texture, source, dest, origin, rotation, tint);
}
fn drawWater() void {
    const time: f32 = @floatCast(rl.getTime() / 2);
    const screenWidth: f32 = @as(f32, @floatFromInt(rl.getScreenWidth()));
    const screenHeight: f32 = @as(f32, @floatFromInt(rl.getScreenHeight()));
    //Parameters
    const waveLength: f32 = screenWidth / 2.5;
    const amplitude1: f32 = screenHeight * 0.01;
    const amplitude2: f32 = screenHeight * 0.01;
    const baseOffset1: f32 = screenHeight * 0.026;
    const baseOffset2: f32 = -screenHeight * 0.021;

    const heightVariation1: f32 = std.math.sin(time * 0.3) * screenHeight * 0.011;
    const heightVariation2: f32 = std.math.cos(time * 0.4) * screenHeight * 0.0083;

    const segmentCount: i32 = 3;

    rl.beginTextureMode(waterTexture);
    rl.clearBackground(rl.Color.init(0, 0, 0, 0));

    // Draw foreground waves (blue)
    var i: i32 = 0;
    while (i < segmentCount) : (i += 1) {
        const x1 = @as(f32, @floatFromInt(i)) * screenWidth / @as(f32, @floatFromInt(segmentCount));
        const x2 = @as(f32, @floatFromInt(i + 1)) * screenWidth / @as(f32, @floatFromInt(segmentCount));

        const y1 = screenHeight - std.math.sin((x1 / waveLength) * 2.0 * std.math.pi + time + 0.3) * (amplitude1 + heightVariation1) - baseOffset1;
        const y2 = screenHeight - std.math.sin((x2 / waveLength) * 2.0 * std.math.pi + time + 0.3) * (amplitude1 + heightVariation1) - baseOffset1;

        rl.drawLineBezier(rl.Vector2.init(x1, y1), rl.Vector2.init(x2, y2), @floatFromInt(boxSize), Color.blue);
    }
    // Draw background waves (dark blue)
    i = 0;
    while (i < segmentCount) : (i += 1) {
        const x1 = @as(f32, @floatFromInt(i)) * screenWidth / @as(f32, @floatFromInt(segmentCount));
        const x2 = @as(f32, @floatFromInt(i + 1)) * screenWidth / @as(f32, @floatFromInt(segmentCount));

        const y1 = screenHeight - std.math.sin((x1 / waveLength) * 2.0 * std.math.pi + time * 0.9) * (amplitude2 + heightVariation2) - baseOffset2;
        const y2 = screenHeight - std.math.sin((x2 / waveLength) * 2.0 * std.math.pi + time * 0.9) * (amplitude2 + heightVariation2) - baseOffset2;

        rl.drawLineBezier(rl.Vector2.init(x1, y1), rl.Vector2.init(x2, y2), @floatFromInt(boxSize), Color.dark_blue);
    }
    rl.endTextureMode();
    if (builtin.target.os.tag != .emscripten) {
        rl.beginShaderMode(finePixelShader);
    }
    rl.drawTextureRec(waterTexture.texture, rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(waterTexture.texture.width), .height = -@as(f32, @floatFromInt(waterTexture.texture.height)) }, rl.Vector2{ .x = 0, .y = 0 }, rl.Color.init(255, 255, 255, 255));
    rl.endShaderMode();
}
fn fullScreen() void {
    if (rl.isKeyPressed(rl.KeyboardKey.f11) or rl.isKeyPressed(rl.KeyboardKey.f)) {
        rl.toggleFullscreen();
        return;
    }
}
pub fn directionToVec2(dir: player.direction) rl.Vector2 {
    switch (dir) {
        player.direction.up => {
            return rl.Vector2{ .x = 0, .y = -1 };
        },
        player.direction.down => {
            return rl.Vector2{ .x = 0, .y = 1 };
        },
        player.direction.left => {
            return rl.Vector2{ .x = -1, .y = 0 };
        },
        player.direction.right => {
            return rl.Vector2{ .x = 1, .y = 0 };
        },
    }
}
pub fn posMoveable(x: i32, y: i32, direction: player.direction) bool {
    const blk = getBlockWorldGrid(x, y);
    if (blk == box) {
        std.debug.print("Its a block!!\n", .{});
        if (direction == player.direction.up or direction == player.direction.down) {
            check_groups: {
                const current: rl.Vector2 = rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
                const twoAway: rl.Vector2 = if (direction != player.direction.up)
                    rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y - 2) }
                else
                    rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y + 2) };
                std.debug.print("we be gonna up up up you take me higer!! ooahhaahh\n", .{});
                const currentGroup = boxes.boxGroupAtCoord(current) catch break :check_groups;
                std.debug.print("im done hiding now im\n", .{});

                const twoAwayGroup = boxes.boxGroupAtCoord(twoAway) catch break :check_groups;
                std.debug.print("shining like im BORN tooo bbeeeeeee\n", .{});
                std.debug.print("ptr1 {*} ptr2 {*} ", .{ currentGroup.items.ptr, twoAwayGroup.items.ptr });
                if (currentGroup.items.ptr == twoAwayGroup.items.ptr) return false;
            }
        }
        return boxes.canMoveBox(x, y, direction);
    }
    if (blk == vic and player.fruitNumber > 0) {
        return false;
    }
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
        std.debug.print("{}, {} is out of bounds (getBlockAt)\n", .{ @as(i32, @intFromFloat(x)), @as(i32, @intFromFloat(y)) });
        return blockType.null;
    }
    return levelManager.mat16x9[@intFromFloat(new_y)][@intFromFloat(new_x)];
}
pub fn getBlockWorldGrid(x: i32, y: i32) blockType {
    if (x >= 16 or y >= 9 or x < 0 or y < 0) {
        std.debug.print("{}, {} is out of bounds (getBlockWorldGrid) \n", .{ (x), (y) });
        return blockType.null;
    }
    return levelManager.mat16x9[@intCast(y)][@intCast(x)];
}
//Uses screen coords (not box Coords, which are different and used by the mat16x9 array)
pub fn setBlockAt(x: f32, y: f32, block: blockType) void {
    const new_x = x / @as(f32, @floatFromInt(boxSize));
    const new_y = y / @as(f32, @floatFromInt(boxSize));
    if (new_x >= 16 or new_y >= 9 or new_x < 0 or new_y < 0) {
        std.debug.print("Out of bounds\n", .{});
        return;
    }
    levelManager.mat16x9[@intFromFloat(new_y)][@intFromFloat(new_x)] = block;
}
pub fn setBlockWorldGrid(x: f32, y: f32, block: blockType) void {
    if (x >= 16 or y >= 9 or x < 0 or y < 0) {
        std.debug.print("Out of bounds\n", .{});
        return;
    }
    levelManager.mat16x9[@intFromFloat(y)][@intFromFloat(x)] = block;
}

pub fn setWindowSizeFromVector(ScreenSize: rl.Vector2) void {
    rl.setWindowSize(@intFromFloat(ScreenSize.x), @intFromFloat(ScreenSize.y));
    boxSize = @divExact(rl.getScreenWidth(), 16);
    gui.guiSetStyle(gui.GuiControl.default, gui.GuiDefaultProperty.text_size, @divTrunc(rl.getScreenWidth(), 64));
    backgroundTexture = rl.loadRenderTexture(@intFromFloat(ScreenSize.x), @intFromFloat(ScreenSize.y));
    waterTexture = rl.loadRenderTexture(@intFromFloat(ScreenSize.x), @intFromFloat(ScreenSize.y));
}
