const game = @import("game.zig");
const rl = @import("raylib");
const std = @import("std");
const levelManager = @import("maps\\levelManager.zig");

pub const pos = struct {
    x: i32,
    y: i32,
};
const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const nul = blockType.null;
const direction = enum { up, down, left, right };
var movementLocked = false;
var canFall = false;
//Current Map State.
pub var mat16x9 = [9][16]blockType{
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
    [_]blockType{ nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul, nul },
};
//Player history!
pub var undoHistory = std.ArrayList(std.ArrayList(pos)).init(std.heap.page_allocator);
pub var redoHistory = std.ArrayList(std.ArrayList(pos)).init(std.heap.page_allocator);

//Player body.
//0 is always the head, body.items.len is always the floating tail (The square right behind the tail. )
var body = std.ArrayList(pos).init(std.heap.page_allocator);

//Moves the player and adds their previous position to player history. (If the move is valid ofc)
pub fn updatePos() void {
    if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
        initPlayer();
    }
    if (movementLocked) return;
    if (rl.isKeyPressed(rl.KeyboardKey.key_w) and (body.items[0].y) - game.boxSize >= 0) {
        if (game.posMoveable(body.items[0].x, body.items[0].y - game.boxSize)) {
            movePlayer(direction.up);
        }
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_a) and body.items[0].x - game.boxSize >= 0) {
        if (game.posMoveable(body.items[0].x - game.boxSize, body.items[0].y)) {
            movePlayer(direction.left);
        }
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_s) and body.items[0].y + game.boxSize <= game.screenHeight - game.boxSize) {
        if (game.posMoveable(body.items[0].x, body.items[0].y + game.boxSize)) {
            movePlayer(direction.down);
        }
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_d) and body.items[0].x + game.boxSize <= game.screenWidth - game.boxSize) {
        if (game.posMoveable(body.items[0].x + game.boxSize, body.items[0].y)) {
            movePlayer(direction.right);
        }
    }
}
fn movePlayer(dir: direction) void {
    var i: usize = body.items.len;
    const tail = body.items[body.items.len - 1];
    while (i > 1) {
        i -= 1;
        body.items[i] = body.items[i - 1];
    }
    switch (dir) {
        direction.right => {
            body.items[0].x += game.boxSize;
        },
        direction.left => {
            body.items[0].x -= game.boxSize;
        },
        direction.up => {
            body.items[0].y -= game.boxSize;
        },
        direction.down => {
            body.items[0].y += game.boxSize;
        },
    }
    if (game.getBlockAt(body.items[0].x, body.items[0].y) == frt) {
        body.append(tail) catch |err| {
            std.debug.print("Failed to append position: {}\n", .{err});
            return;
        };
    } else {
        game.setBlockAt(tail.x, tail.y, air);
    }
    game.setBlockAt(body.items[0].x, body.items[0].y, bdy);
}
pub fn updateGravity() void {
    var i: usize = body.items.len;
    canFall = true;
    movementLocked = false;
    while (i > 0) {
        i -= 1;
        const block = game.getBlockAt(body.items[i].x, body.items[i].y + game.boxSize);
        if (block == sol or block == frt) {
            canFall = false;
            movementLocked = false;
            break;
        }
        if (block == blockType.null) {
            body.clearAndFree();
            initPlayer();
        }
    }
    if (canFall) {
        movementLocked = true;
        i = body.items.len;
        while (i > 0) {
            i -= 1;
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
        body.items[i].y += @intFromFloat(1000.0 * rl.getFrameTime());
    }
}

pub fn drawPlayer(texture: rl.Texture) void {
    for (body.items) |elem| {
        rl.drawTexture(texture, elem.x, elem.y, rl.Color.white);
    }
    for (mat16x9, 0..) |row, rIndex| {
        for (row, 0..) |element, cIndex| {
            if (element == blockType.bdy) {
                const rw: i32 = @intCast(cIndex);
                const col: i32 = @intCast(rIndex);
                rl.drawTexture(texture, game.boxSize * rw, col * game.boxSize, rl.Color.white);
            }
        }
    }
}
pub fn initPlayer() void {
    body.clearAndFree();
    movementLocked = false;
    canFall = false;
    mat16x9 = levelManager.getLevel();
    const tempBody = levelManager.getBody();

    for (tempBody) |elem| {
        body.append(elem) catch |err| {
            std.debug.print("Failed to append position: {}\n", .{err});
            return;
        };
    }

    var i = body.items.len;
    while (i > 0) {
        i -= 1;
        game.setBlockAt(body.items[i].x, body.items[i].y, bdy);
    }
}
//pub fn loadBody([]body)
