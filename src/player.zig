const game = @import("game.zig");
const boxes = @import("boxes.zig");
const rl = @import("raylib");
const std = @import("std");
const levelManager = @import("maps/levelManager.zig");
const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const box = blockType.box;
pub const direction = enum { up, down, left, right };
var movementLocked = false;
var canFall = false;

pub var fruitNumber: i32 = 0;
//Player history!
pub var undoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);
var mapHistory = std.ArrayList([9][16]blockType).init(std.heap.c_allocator);

pub var redoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);

//Player body.
//0 is always the head, body.items.len is always the floating tail (The square right behind the tail. )
pub var body = std.ArrayList(rl.Vector2).init(std.heap.c_allocator);

pub var players = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);

pub fn numFruit() i32 {
    var numberOfFruit: i32 = 0;
    for (levelManager.mat16x9) |map| {
        for (map) |block| {
            if (block == game.blockType.frt) {
                numberOfFruit += 1;
            }
        }
    }
    return numberOfFruit;
}
//Moves the player and adds their previous position to player history. (If the move is valid ofc)
pub fn updatePos() void {
    if (rl.isKeyPressed(rl.KeyboardKey.r)) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum()));
    }
    if (movementLocked) return;

    if (rl.isKeyPressed(rl.KeyboardKey.z) or rl.isKeyPressed(rl.KeyboardKey.backspace)) {
        undo();
    }
    if (rl.isKeyPressed(rl.KeyboardKey.y) or rl.isKeyPressed(rl.KeyboardKey.r)) {
        redo();
    }

    if ((rl.isKeyPressed(rl.KeyboardKey.w) or (rl.isKeyPressed(rl.KeyboardKey.up))) and (body.items[0].y) - 1 >= 0) {
        if (game.posMoveable(@intFromFloat(body.items[0].x), @intFromFloat(body.items[0].y - 1), direction.up)) {
            movePlayer(direction.up);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.a) or (rl.isKeyPressed(rl.KeyboardKey.left))) and body.items[0].x - 1 >= 0) {
        if (game.posMoveable(@intFromFloat(body.items[0].x - 1), @intFromFloat(body.items[0].y), direction.left)) {
            movePlayer(direction.left);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.s) or (rl.isKeyPressed(rl.KeyboardKey.down))) and body.items[0].y + 1 < 9) {
        if (game.posMoveable(@intFromFloat(body.items[0].x), @intFromFloat(body.items[0].y + 1), direction.down)) {
            movePlayer(direction.down);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.d) or (rl.isKeyPressed(rl.KeyboardKey.right))) and body.items[0].x + 1 < 16) {
        if (game.posMoveable(@intFromFloat(body.items[0].x + 1), @intFromFloat(body.items[0].y), direction.right)) {
            movePlayer(direction.right);
        }
    }
}
fn undo() void {
    if (undoHistory.items.len <= 0) return;
    const oldBody = body.clone() catch |err| {
        std.debug.print("Failed to clone body: {}\n", .{err});
        return;
    };
    redoHistory.append(oldBody) catch |err| {
        std.debug.print("Failed to append redo history r edo: {}\n", .{err});
        return;
    };
    body = undoHistory.pop();

    levelManager.mat16x9 = mapHistory.pop();
}

fn redo() void {
    if (redoHistory.items.len <= 0) return;
    var i: usize = 0;
    while (i < body.items.len) {
        game.setBlockWorldGrid(body.items[i].x, body.items[i].y, air);
        i += 1;
    }
    const clone = body.clone() catch |err| {
        std.debug.print("Failed to clone body redo: {}\n", .{err});
        return;
    };
    undoHistory.append(clone) catch |err| {
        std.debug.print("Failed to append undo position: {}\n", .{err});
        return;
    };
    mapHistory.append(levelManager.mat16x9) catch |err| {
        std.debug.print("Failed to append map history: {}\n", .{err});
        return;
    };
    body = redoHistory.pop();
    i = 0;
    while (i < body.items.len) {
        game.setBlockWorldGrid((body.items[i].x), (body.items[i].y), bdy);
        i += 1;
    }
}
fn movePlayer(dir: direction) void {
    redoHistory.clearAndFree();

    const clone = body.clone() catch |err| {
        std.debug.print("Failed to clone body: {}\n", .{err});
        return;
    };
    undoHistory.append(clone) catch |err| {
        std.debug.print("Failed to append undo history: {}\n", .{err});
        return;
    };
    mapHistory.append(levelManager.mat16x9) catch |err| {
        std.debug.print("Failed to append map history: {}\n", .{err});
        return;
    };
    var i: usize = body.items.len;
    const tail = body.items[body.items.len - 1];
    while (i > 1) {
        i -= 1;
        body.items[i] = body.items[i - 1];
    }
    switch (dir) {
        direction.right => {
            body.items[0].x += 1;
        },
        direction.left => {
            body.items[0].x -= 1;
        },
        direction.up => {
            body.items[0].y -= 1;
        },
        direction.down => {
            body.items[0].y += 1;
        },
    }
    std.log.info("body x / y {} {}", .{ @as(i32, @intFromFloat(body.items[0].x)), @as(i32, @intFromFloat(body.items[0].y)) });

    const newHead = game.getBlockWorldGrid(@intFromFloat(body.items[0].x), @intFromFloat(body.items[0].y));

    if (newHead == blockType.vic) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum() + 1));
        return;
    }
    if (newHead == blockType.spk) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum()));
        return;
    }
    if (newHead == blockType.box) {
        boxes.movePos(body.items[0], dir);
    }
    if (newHead == blockType.frt) {
        fruitNumber -= 1;
        body.append(tail) catch |err| {
            std.debug.print("Failed to append body position: {}\n", .{err});
            return;
        };
    } else {
        game.setBlockWorldGrid((tail.x), (tail.y), air);
    }
    if (body.items.len > 0) game.setBlockWorldGrid((body.items[0].x), (body.items[0].y), bdy);
}
pub fn updateGravity() void {
    var i: usize = body.items.len;
    canFall = true;
    movementLocked = false;
    var shouldDie = false;
    while (i > 0) {
        i -= 1;
        const block = game.getBlockWorldGrid(@intFromFloat(body.items[i].x), @intFromFloat(body.items[i].y + 1));
        if (block == sol or block == frt) {
            canFall = false;
            movementLocked = false;
            break;
        }
        if (block == box) {
            const boxCanFall = boxes.canMoveBox(@intFromFloat(body.items[i].x), @intFromFloat(body.items[i].y + 1), direction.down);
            if (!boxCanFall) {
                canFall = false;
                movementLocked = false;
                break;
            }
        }
        if (block == blockType.null) {
            levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum()));
        }
        if (block == blockType.spk) {
            shouldDie = true;
        }
    }
    if (canFall) {
        if (shouldDie) {
            levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum()));
            return;
        }
        movementLocked = true;
        i = body.items.len;
        while (i > 0) {
            i -= 1;
            const block = game.getBlockWorldGrid(@intFromFloat(body.items[i].x), @intFromFloat(body.items[i].y + 1));
            if (block == blockType.vic) {
                levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum() + 1));
                break;
            }
            game.setBlockWorldGrid((body.items[i].x), (body.items[i].y), air);
        }
        fall();
    } else if (game.getBlockWorldGrid(@intFromFloat(body.items[i].x), @intFromFloat(body.items[i].y)) == air) {
        i = body.items.len;
        while (i > 0) {
            i -= 1;
            game.setBlockWorldGrid((body.items[i].x), (body.items[i].y), bdy);
        }
    }
    if (!canFall) {
        i = body.items.len;
        while (i > 0) {
            i -= 1;
            if (@mod(body.items[i].y, @as(f32, @floatFromInt(game.boxSize))) > 0) {
                body.items[i].y = @floatFromInt(@as(i32, @intFromFloat(body.items[i].y)));
            }
        }
    }
}
fn fall() void {
    var i: usize = body.items.len;
    while (i > 0) {
        i -= 1;
        body.items[i].y += 10 * rl.getFrameTime();
    }
}

pub fn drawPlayer(textures: []const rl.Texture, custom_body: ?std.ArrayList(rl.Vector2)) void {
    const body_to_use = if (custom_body) |cb| cb.items else body.items;
    for (body_to_use, 0..) |elem, i| {
        if (i == 0) {
            game.drawTexture(textures[0], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
        } else if (@mod(i, 2) == 1) {
            game.drawTexture(textures[1], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
        } else {
            game.drawTexture(textures[2], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
        }
    }
}
pub fn clearPlayer() void {
    body.clearAndFree();
    clearPlayerAndMap();
    boxes.clearBoxes();
    undoHistory.clearAndFree();
    redoHistory.clearAndFree();
    mapHistory.clearAndFree();
    movementLocked = false;
    canFall = false;
}
pub fn clearPlayerAndMap() void {
    levelManager.mat16x9 = [9][16]blockType{
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
        [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    };
    body.clearAndFree();
    boxes.clearBoxes();
}
