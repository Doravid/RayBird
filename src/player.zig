const game = @import("game.zig");
const boxes = @import("boxes.zig");
const rl = @import("raylib");
const movement = @import("movement.zig");

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
pub var currentPlayerIndex: usize = 0;
var fallingPlayers = std.ArrayList(bool).init(std.heap.c_allocator);
pub var fruitNumber: i32 = 0;
//Player history!
pub var undoHistory = std.ArrayList(std.ArrayList(std.ArrayList(rl.Vector2))).init(std.heap.c_allocator);
pub var redoHistory = std.ArrayList(std.ArrayList(std.ArrayList(rl.Vector2))).init(std.heap.c_allocator);

var dynamic_mapHistory = std.ArrayList(std.AutoHashMap(std.meta.Tuple(&.{ i32, i32 }), game.blockType)).init(std.heap.c_allocator);

//For each player index 0 is always the head items.len is always the floating tail (The square right behind the tail. )
pub var playerList = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);

pub fn numFruit() i32 {
    var numberOfFruit: i32 = 0;
    var iter = levelManager.dynamic_map.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.* == game.blockType.frt) {
            numberOfFruit += 1;
        }
    }
    return numberOfFruit;
}

pub fn updatePos() void {
    if (playerList.items.len == 0 or currentPlayerIndex >= playerList.items.len or playerList.items[currentPlayerIndex].items.len == 0) return;

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
    if (rl.isKeyPressed(rl.KeyboardKey.tab)) {
        if (playerList.items.len > 0) {
            currentPlayerIndex = (currentPlayerIndex + 1) % playerList.items.len;
        }
    }
    var playX: i32 = @intFromFloat(playerList.items[currentPlayerIndex].items[0].x);
    var playY: i32 = @intFromFloat(playerList.items[currentPlayerIndex].items[0].y);
    if ((rl.isKeyPressed(rl.KeyboardKey.w) or rl.isKeyPressed(rl.KeyboardKey.up))) {
        playY -= 1;
        if (!isOwnBodyAt(playX, playY) and movement.canPush(playX, playY, direction.up) and movement.isStationary()) {
            movePlayer(direction.up);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.s) or rl.isKeyPressed(rl.KeyboardKey.down))) {
        playY += 1;
        if (!isOwnBodyAt(playX, playY) and movement.canPush(playX, playY, direction.down) and movement.isStationary()) {
            movePlayer(direction.down);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.a) or rl.isKeyPressed(rl.KeyboardKey.left))) {
        playX -= 1;
        if (!isOwnBodyAt(playX, playY) and movement.canPush(playX, playY, direction.left) and movement.isStationary()) {
            movePlayer(direction.left);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.d) or rl.isKeyPressed(rl.KeyboardKey.right))) {
        playX += 1;
        if (!isOwnBodyAt(playX, playY) and movement.canPush(playX, playY, direction.right) and movement.isStationary()) {
            movePlayer(direction.right);
        }
    }
}
fn undo() void {
    if (undoHistory.items.len <= 0) return;
    boxes.undo();
    const oldBody = playerList.clone() catch |err| {
        std.debug.print("Failed to clone playerList: {}\n", .{err});
        return;
    };
    redoHistory.append(oldBody) catch |err| {
        std.debug.print("Failed to append redo history: {}\n", .{err});
        return;
    };
    playerList = undoHistory.pop();

    levelManager.dynamic_map = dynamic_mapHistory.pop();
    fruitNumber = numFruit();
}

fn redo() void {
    if (redoHistory.items.len <= 0) return;
    boxes.redo();
    const clone = playerList.clone() catch |err| {
        std.debug.print("Failed to clone body redo: {}\n", .{err});
        return;
    };
    undoHistory.append(clone) catch |err| {
        std.debug.print("Failed to append undo position: {}\n", .{err});
        return;
    };

    const map_clone = levelManager.dynamic_map.clone() catch |err| {
        std.debug.print("Failed to clone map redo: {}\n", .{err});
        return;
    };

    dynamic_mapHistory.append(map_clone) catch |err| {
        std.debug.print("Failed to append map history: {}\n", .{err});
        return;
    };

    playerList = redoHistory.pop();
    fruitNumber = numFruit();
}
fn movePlayer(dir: direction) void {
    redoHistory.clearAndFree();
    const historyClone = deepClonePlayerList(playerList) catch |err| {
        std.debug.print("{}\n", .{err});
        return;
    };
    undoHistory.append(historyClone) catch |err| {
        std.debug.print("{}\n", .{err});
        return;
    };
    const boxClone = deepClonePlayerList(boxes.boxList) catch |err| {
        std.debug.print("{}\n", .{err});
        return;
    };
    boxes.boxUndoHistory.append(boxClone) catch |err| {
        std.debug.print("{}\n", .{err});
        return;
    };

    std.debug.print("\n5\n", .{});

    const map_clone = levelManager.dynamic_map.clone() catch |err| {
        std.debug.print("Failed to clone map: {}\n", .{err});
        return;
    };
    dynamic_mapHistory.append(map_clone) catch |err| {
        std.debug.print("Failed to append map history: {}\n", .{err});
        return;
    };
    var i: usize = playerList.items[currentPlayerIndex].items.len;
    const tail = playerList.items[currentPlayerIndex].items[playerList.items[currentPlayerIndex].items.len - 1];
    while (i > 1) {
        i -= 1;
        playerList.items[currentPlayerIndex].items[i] = playerList.items[currentPlayerIndex].items[i - 1];
    }
    const newHeadPos: rl.Vector2 = switch (dir) {
        direction.right => rl.Vector2.add(playerList.items[currentPlayerIndex].items[0], rl.Vector2{ .x = 1, .y = 0 }),
        direction.left => rl.Vector2.add(playerList.items[currentPlayerIndex].items[0], rl.Vector2{ .x = -1, .y = 0 }),
        direction.up => rl.Vector2.add(playerList.items[currentPlayerIndex].items[0], rl.Vector2{ .x = 0, .y = -1 }),
        direction.down => rl.Vector2.add(playerList.items[currentPlayerIndex].items[0], rl.Vector2{ .x = 0, .y = 1 }),
    };
    std.log.info("body x / y {} {}", .{ @as(i32, @intFromFloat(playerList.items[currentPlayerIndex].items[0].x)), @as(i32, @intFromFloat(playerList.items[currentPlayerIndex].items[0].y)) });

    const newHead = game.getBlockWorldGrid(@intFromFloat(newHeadPos.x), @intFromFloat(newHeadPos.y));

    if (newHead == blockType.vic) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum() + 1));
        return;
    }
    if (newHead == blockType.spk) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum()));
        return;
    }
    if (newHead == blockType.box or newHead == blockType.bdy) {
        std.debug.print("pushing: {}, {} from {}, {}", .{ newHeadPos.x, newHeadPos.y, playerList.items[currentPlayerIndex].items[0].x, playerList.items[currentPlayerIndex].items[0].y });
        movement.applyPush(@intFromFloat(newHeadPos.x), @intFromFloat(newHeadPos.y), dir);
    }
    if (newHead == blockType.frt) {
        fruitNumber -= 1;
        playerList.items[currentPlayerIndex].append(tail) catch |err| {
            std.debug.print("Failed to append body position: {}\n", .{err});
            return;
        };
    } else {
        game.setBlockWorldGrid((tail.x), (tail.y), air);
    }
    playerList.items[currentPlayerIndex].items[0] = newHeadPos;
    if (playerList.items[currentPlayerIndex].items.len > 0) game.setBlockWorldGrid((playerList.items[currentPlayerIndex].items[0].x), (playerList.items[currentPlayerIndex].items[0].y), bdy);
    var spkVist = false;
    var standing = false;
    for (playerList.items[currentPlayerIndex].items) |cell| {
        const curBlock = game.getBlockWorldGrid(@intFromFloat(cell.x), @intFromFloat(cell.y + 1));
        if (curBlock == spk) {
            spkVist = true;
        }
        if (curBlock == frt or curBlock == sol) {
            standing = true;
        }
    }
    if (spkVist and !standing) {
        undo();
    }
}

pub fn drawPlayer(textures: []const rl.Texture) void {
    for (playerList.items, 0..) |playerBody, bodyNum| {
        for (playerBody.items, 0..) |elem, i| {
            if (bodyNum % 2 == 0) {
                if (i == 0) {
                    game.drawTexture(textures[0], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
                } else if (@mod(i, 2) == 1) {
                    game.drawTexture(textures[1], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
                } else {
                    game.drawTexture(textures[2], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
                }
            } else {
                if (i == 0) {
                    game.drawTexture(textures[3], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
                } else if (@mod(i, 2) == 1) {
                    game.drawTexture(textures[4], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
                } else {
                    game.drawTexture(textures[5], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
                }
            }
        }
    }
}

pub fn clearPlayerAndMap() void {
    playerList.clearAndFree();
    boxes.clearBoxes();
    undoHistory.clearAndFree();
    redoHistory.clearAndFree();
    fallingPlayers.clearAndFree();
    movementLocked = false;
    canFall = false;
    levelManager.dynamic_map.clearAndFree();
}

fn isOwnBodyAt(x: i32, y: i32) bool {
    if (currentPlayerIndex >= playerList.items.len) return false;

    for (playerList.items[currentPlayerIndex].items) |segment| {
        if (@as(i32, @intFromFloat(segment.x)) == x and
            @as(i32, @intFromFloat(segment.y)) == y)
        {
            return true;
        }
    }
    return false;
}
fn deepClonePlayerList(
    src: std.ArrayList(std.ArrayList(rl.Vector2)),
) !std.ArrayList(std.ArrayList(rl.Vector2)) {
    var out = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);
    for (src.items) |playerBody| {
        var bodyClone = std.ArrayList(rl.Vector2).init(std.heap.c_allocator);
        try bodyClone.appendSlice(playerBody.items);
        try out.append(bodyClone);
    }
    std.debug.print("\ndeepClonePlayerList makes it\n", .{});
    return out;
}
