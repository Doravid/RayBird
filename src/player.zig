const game = @import("game.zig");
const rl = @import("raylib");
const std = @import("std");
const levelManager = @import("maps\\levelManager.zig");
const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const direction = enum { up, down, left, right };
var movementLocked = false;
var canFall = false;
//Current Map State.

pub var mat16x9 = [9][16]blockType{
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
//Player history!
pub var undoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.page_allocator);
var mapHistory = std.ArrayList([9][16]blockType).init(std.heap.page_allocator);

pub var redoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.page_allocator);

//Player body.
//0 is always the head, body.items.len is always the floating tail (The square right behind the tail. )
pub var body = std.ArrayList(rl.Vector2).init(std.heap.page_allocator);

//Moves the player and adds their previous position to player history. (If the move is valid ofc)
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

    if ((rl.isKeyPressed(rl.KeyboardKey.w) or (rl.isKeyPressed(rl.KeyboardKey.up))) and (body.items[0].y) - @as(f32, @floatFromInt(game.boxSize)) >= 0) {
        std.debug.print("{}", .{body.items[0].y});
        if (game.posMoveable(body.items[0].x, body.items[0].y - @as(f32, @floatFromInt(game.boxSize)))) {
            movePlayer(direction.up);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.a) or (rl.isKeyPressed(rl.KeyboardKey.left))) and body.items[0].x - @as(f32, @floatFromInt(game.boxSize)) >= 0) {
        if (game.posMoveable(body.items[0].x - @as(f32, @floatFromInt(game.boxSize)), body.items[0].y)) {
            movePlayer(direction.left);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.s) or (rl.isKeyPressed(rl.KeyboardKey.down))) and body.items[0].y + @as(f32, @floatFromInt(game.boxSize)) <= @as(f32, @floatFromInt(game.screenWidth - game.boxSize))) {
        if (game.posMoveable(body.items[0].x, body.items[0].y + @as(f32, @floatFromInt(game.boxSize)))) {
            movePlayer(direction.down);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.d) or (rl.isKeyPressed(rl.KeyboardKey.right))) and body.items[0].x + @as(f32, @floatFromInt(game.boxSize)) <= @as(f32, @floatFromInt(game.screenWidth - game.boxSize))) {
        if (game.posMoveable(body.items[0].x + @as(f32, @floatFromInt(game.boxSize)), body.items[0].y)) {
            movePlayer(direction.right);
        }
    }
}
fn undo() void {
    if (undoHistory.items.len <= 0) return;
    const oldBody = body.clone() catch |err| {
        std.debug.print("Failed to append position: {}\n", .{err});
        return;
    };
    redoHistory.append(oldBody) catch |err| {
        std.debug.print("Failed to append position: {}\n", .{err});
        return;
    };
    body = undoHistory.pop();

    mat16x9 = mapHistory.pop();
}

fn redo() void {
    if (redoHistory.items.len <= 0) return;
    var i: usize = 0;
    while (i < body.items.len) {
        game.setBlockAt(body.items[i].x, body.items[i].y, air);
        i += 1;
    }
    const clone = body.clone() catch |err| {
        std.debug.print("Failed to append position: {}\n", .{err});
        return;
    };
    undoHistory.append(clone) catch |err| {
        std.debug.print("Failed to append position: {}\n", .{err});
        return;
    };
    mapHistory.append(mat16x9) catch |err| {
        std.debug.print("Failed to append position: {}\n", .{err});
        return;
    };
    body = redoHistory.pop();
    i = 0;
    while (i < body.items.len) {
        game.setBlockAt(body.items[i].x, body.items[i].y, bdy);
        i += 1;
    }
}
fn movePlayer(dir: direction) void {
    redoHistory.clearAndFree();

    const clone = body.clone() catch |err| {
        std.debug.print("Failed to append position: {}\n", .{err});
        return;
    };
    undoHistory.append(clone) catch |err| {
        std.debug.print("Failed to append position: {}\n", .{err});
        return;
    };
    mapHistory.append(mat16x9) catch |err| {
        std.debug.print("Failed to append position: {}\n", .{err});
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
            body.items[0].x += @as(f32, @floatFromInt(game.boxSize));
        },
        direction.left => {
            body.items[0].x -= @as(f32, @floatFromInt(game.boxSize));
        },
        direction.up => {
            body.items[0].y -= @as(f32, @floatFromInt(game.boxSize));
        },
        direction.down => {
            body.items[0].y += @as(f32, @floatFromInt(game.boxSize));
        },
    }
    const newHead = game.getBlockAt(body.items[0].x, body.items[0].y);
    if (newHead == blockType.vic) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum() + 1));
    }
    if (newHead == blockType.spk) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum()));
    }
    if (newHead == blockType.frt) {
        body.append(tail) catch |err| {
            std.debug.print("Failed to append position: {}\n", .{err});
            return;
        };
    } else {
        game.setBlockAt(tail.x, tail.y, air);
    }
    if (body.items.len > 0) game.setBlockAt(body.items[0].x, body.items[0].y, bdy);
}
pub fn updateGravity() void {
    var i: usize = body.items.len;
    canFall = true;
    movementLocked = false;
    var shouldDie = false;
    while (i > 0) {
        i -= 1;
        const block = game.getBlockAt(body.items[i].x, body.items[i].y + @as(f32, @floatFromInt(game.boxSize)));
        if (block == sol or block == frt) {
            canFall = false;
            movementLocked = false;
            break;
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

            const block = game.getBlockAt(body.items[i].x, body.items[i].y + @as(f32, @floatFromInt(game.boxSize)));
            if (block == blockType.vic) {
                levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum() + 1));
                break;
            }

            game.setBlockAt(body.items[i].x, body.items[i].y, air);
        }
        fall();
    } else if (game.getBlockAt(body.items[0].x, body.items[0].y) == air) {
        i = body.items.len;
        while (i > 0) {
            i -= 1;
            game.setBlockAt(body.items[i].x, body.items[i].y, bdy);
        }
    }
}
fn fall() void {
    var i: usize = body.items.len;
    while (i > 0) {
        i -= 1;
        body.items[i].y += 7 * @as(f32, @floatFromInt(game.boxSize)) * rl.getFrameTime();
    }
}

pub fn drawPlayer(texture: rl.Texture) void {
    for (body.items) |elem| {
        game.drawTexture(texture, @intFromFloat(elem.x), @intFromFloat(elem.y), rl.Color.white);
    }
}
pub fn clearPlayer() void {
    body.clearAndFree();
    undoHistory.clearAndFree();
    redoHistory.clearAndFree();
    mapHistory.clearAndFree();
    movementLocked = false;
    canFall = false;
}
pub fn clearPlayerAndMap() void {
    mat16x9 = [9][16]blockType{
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
}
