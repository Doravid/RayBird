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
pub var undoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);
var mapHistory = std.ArrayList([9][16]blockType).init(std.heap.c_allocator);

pub var redoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);

//Player body.
//0 is always the head, playerList.items[currentPlayerIndex].items.len is always the floating tail (The square right behind the tail. )
// pub var body = std.ArrayList(rl.Vector2).init(std.heap.c_allocator);

pub var playerList = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);

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
        if (playY >= 0 and !isOwnBodyAt(playX, playY) and movement.canPush(playX, playY, direction.up)) {
            movePlayer(direction.up);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.s) or rl.isKeyPressed(rl.KeyboardKey.down))) {
        playY += 1;
        if (playY >= 0 and !isOwnBodyAt(playX, playY) and movement.canPush(playX, playY, direction.down)) {
            movePlayer(direction.down);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.a) or rl.isKeyPressed(rl.KeyboardKey.left))) {
        playX -= 1;
        if (playY >= 0 and !isOwnBodyAt(playX, playY) and movement.canPush(playX, playY, direction.left)) {
            movePlayer(direction.left);
        }
    }
    if ((rl.isKeyPressed(rl.KeyboardKey.d) or rl.isKeyPressed(rl.KeyboardKey.right))) {
        playX += 1;
        if (playY >= 0 and !isOwnBodyAt(playX, playY) and movement.canPush(playX, playY, direction.right)) {
            movePlayer(direction.right);
        }
    }
}
fn undo() void {
    // if (undoHistory.items.len <= 0) return;
    // const oldBody = body.clone() catch |err| {
    //     std.debug.print("Failed to clone body: {}\n", .{err});
    //     return;
    // };
    // redoHistory.append(oldBody) catch |err| {
    //     std.debug.print("Failed to append redo history r edo: {}\n", .{err});
    //     return;
    // };
    // body = undoHistory.pop();

    // levelManager.mat16x9 = mapHistory.pop();
}

fn redo() void {
    // if (redoHistory.items.len <= 0) return;
    // var i: usize = 0;
    // while (i < playerList.items[currentPlayerIndex].items.len) {
    //     game.setBlockWorldGrid(playerList.items[currentPlayerIndex].items[i].x, playerList.items[currentPlayerIndex].items[i].y, air);
    //     i += 1;
    // }
    // const clone = body.clone() catch |err| {
    //     std.debug.print("Failed to clone body redo: {}\n", .{err});
    //     return;
    // };
    // undoHistory.append(clone) catch |err| {
    //     std.debug.print("Failed to append undo position: {}\n", .{err});
    //     return;
    // };
    // mapHistory.append(levelManager.mat16x9) catch |err| {
    //     std.debug.print("Failed to append map history: {}\n", .{err});
    //     return;
    // };
    // body = redoHistory.pop();
    // i = 0;
    // while (i < playerList.items[currentPlayerIndex].items.len) {
    //     game.setBlockWorldGrid((playerList.items[currentPlayerIndex].items[i].x), (playerList.items[currentPlayerIndex].items[i].y), bdy);
    //     i += 1;
    // }
}
fn movePlayer(dir: direction) void {
    redoHistory.clearAndFree();

    mapHistory.append(levelManager.mat16x9) catch |err| {
        std.debug.print("Failed to append map history: {}\n", .{err});
        return;
    };
    var i: usize = playerList.items[currentPlayerIndex].items.len;
    const tail = playerList.items[currentPlayerIndex].items[playerList.items[currentPlayerIndex].items.len - 1];
    while (i > 1) {
        i -= 1;
        playerList.items[currentPlayerIndex].items[i] = playerList.items[currentPlayerIndex].items[i - 1];
    }
    switch (dir) {
        direction.right => {
            playerList.items[currentPlayerIndex].items[0].x += 1;
        },
        direction.left => {
            playerList.items[currentPlayerIndex].items[0].x -= 1;
        },
        direction.up => {
            playerList.items[currentPlayerIndex].items[0].y -= 1;
        },
        direction.down => {
            playerList.items[currentPlayerIndex].items[0].y += 1;
        },
    }
    std.log.info("body x / y {} {}", .{ @as(i32, @intFromFloat(playerList.items[currentPlayerIndex].items[0].x)), @as(i32, @intFromFloat(playerList.items[currentPlayerIndex].items[0].y)) });

    const newHead = game.getBlockWorldGrid(@intFromFloat(playerList.items[currentPlayerIndex].items[0].x), @intFromFloat(playerList.items[currentPlayerIndex].items[0].y));

    if (newHead == blockType.vic) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum() + 1));
        return;
    }
    if (newHead == blockType.spk) {
        levelManager.setLevel(@intCast(levelManager.getCurrentLevelNum()));
        return;
    }
    if (newHead == blockType.box) {
        const headX = @as(i32, @intFromFloat(playerList.items[currentPlayerIndex].items[0].x));
        const headY = @as(i32, @intFromFloat(playerList.items[currentPlayerIndex].items[0].y));
        movement.applyPush(headX, headY, dir);
    }
    if (newHead == blockType.bdy) {
        const headX = @as(i32, @intFromFloat(playerList.items[currentPlayerIndex].items[0].x));
        const headY = @as(i32, @intFromFloat(playerList.items[currentPlayerIndex].items[0].y));
        if (findPlayerAtPosition(headX, headY)) |otherPlayerIndex| {
            if (otherPlayerIndex != currentPlayerIndex) {
                movement.applyPush(headX, headY, dir);
            }
        }
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
    if (playerList.items[currentPlayerIndex].items.len > 0) game.setBlockWorldGrid((playerList.items[currentPlayerIndex].items[0].x), (playerList.items[currentPlayerIndex].items[0].y), bdy);
}

pub fn drawPlayer(textures: []const rl.Texture) void {
    for (playerList.items) |playerBody| {
        for (playerBody.items, 0..) |elem, i| {
            if (i == 0) {
                game.drawTexture(textures[0], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
            } else if (@mod(i, 2) == 1) {
                game.drawTexture(textures[1], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
            } else {
                game.drawTexture(textures[2], @as(i32, @intFromFloat(elem.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(elem.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
            }
        }
    }
}
pub fn clearPlayer() void {
    playerList.deinit();
    clearPlayerAndMap();
    boxes.clearBoxes();
    undoHistory.clearAndFree();
    redoHistory.clearAndFree();
    mapHistory.clearAndFree();
    fallingPlayers.clearAndFree();
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
    playerList.deinit();
    boxes.clearBoxes();
}

pub fn findPlayerAtPosition(x: i32, y: i32) ?usize {
    for (playerList.items, 0..) |playerBody, i| {
        if (i == currentPlayerIndex) continue;
        for (playerBody.items) |segment| {
            if (@as(i32, @intFromFloat(segment.x)) == x and @as(i32, @intFromFloat(segment.y)) == y) {
                return i;
            }
        }
    }
    return null;
}

fn canGroupFall(boxGroup: std.ArrayList(rl.Vector2)) bool {
    for (boxGroup.items) |curBox| {
        const gridX = @as(i32, @intFromFloat(curBox.x));
        const gridY = @as(i32, @intFromFloat(curBox.y));
        if (gridY + 1 >= 9) return false;
        const blockBelow = game.getBlockWorldGrid(gridX, gridY + 1);
        if (blockBelow == sol or blockBelow == frt) return false;
        if (blockBelow == box) {
            if (!boxes.canGroupMove(boxGroup, direction.down)) return false;
        }
        if (boxes.isPlayerAtPosition(@floatFromInt(gridX), @floatFromInt(gridY + 1))) return false;
    }
    return true;
}

fn fallPlayerGroup(playerIndex: usize) void {
    if (playerIndex >= playerList.items.len) return;
    for (playerList.items[playerIndex].items) |*segment| {
        segment.*.y += 10 * rl.getFrameTime();
    }
}

pub fn canGroupMove(boxGroup: std.ArrayList(rl.Vector2), dir: direction) bool {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var affectedGroups = std.ArrayList(usize).init(allocator);
    var visitedGroups = std.AutoHashMap(usize, void).init(allocator);
    var queue = std.ArrayList(usize).init(allocator);
    var startIndex: ?usize = null;
    for (playerList.items, 0..) |group, i| {
        const ptr: std.ArrayList(rl.Vector2) = group;
        if (ptr.items.ptr == boxGroup.items.ptr) {
            startIndex = i;
            break;
        }
    }
    if (startIndex == null) return false;
    queue.append(startIndex.?) catch return false;
    while (queue.items.len > 0) {
        const currentIndex = queue.orderedRemove(0);
        if (visitedGroups.contains(currentIndex)) continue;
        visitedGroups.put(currentIndex, {}) catch return false;
        affectedGroups.append(currentIndex) catch return false;
        for (playerList.items[currentIndex].items) |curBox| {
            const dirVec = boxes.directionToOffset(dir);
            const nextX = @as(i32, @intFromFloat(curBox.x)) + dirVec.x;
            const nextY = @as(i32, @intFromFloat(curBox.y)) + dirVec.y;
            const nextBlock = game.getBlockWorldGrid(nextX, nextY);
            if (nextBlock == box) {
                const nextVec = rl.Vector2{ .x = @floatFromInt(nextX), .y = @floatFromInt(nextY) };
                const nextGroup = playerGroupAtCoord(nextVec) catch continue;
                for (playerList.items, 0..) |groupPtr, i| {
                    const ptr: std.ArrayList(rl.Vector2) = groupPtr;
                    const ptr2: std.ArrayList(rl.Vector2) = nextGroup;
                    if (ptr.items.ptr == ptr2.items.ptr) {
                        if (!visitedGroups.contains(i)) queue.append(i) catch return false;
                        break;
                    }
                }
            }
        }
    }
    var movingPositions = std.AutoHashMap(boxes.Vec2Hash, void).init(allocator);
    for (affectedGroups.items) |groupIndex| {
        for (playerList.items[groupIndex].items) |pos| {
            const hashPos = boxes.Vec2Hash{ .x = @intFromFloat(pos.x), .y = @intFromFloat(pos.y) };
            movingPositions.put(hashPos, {}) catch return false;
        }
    }
    for (affectedGroups.items) |groupIndex| {
        for (playerList.items[groupIndex].items) |curBox| {
            const dirVec = boxes.directionToOffset(dir);
            const nextX = @as(i32, @intFromFloat(curBox.x)) + dirVec.x;
            const nextY = @as(i32, @intFromFloat(curBox.y)) + dirVec.y;
            if (!boxes.isDestinationValid(nextX, nextY, &movingPositions)) return false;
        }
    }
    return true;
}

pub fn playerGroupAtCoord(coord: rl.Vector2) !std.ArrayList(rl.Vector2) {
    for (playerList.items) |boxGroup| {
        if (playerGroupHasCoord(coord, boxGroup)) return boxGroup;
    }
    return boxes.noGroup.noGroupFound;
}
fn playerGroupHasCoord(coord: rl.Vector2, boxGroup: std.ArrayList(rl.Vector2)) bool {
    for (boxGroup.items) |curBox| {
        if (curBox.x == coord.x and curBox.y == coord.y) return true;
    }
    return false;
}
fn canPlayerGroupFall(boxGroup: std.ArrayList(rl.Vector2)) bool {
    for (boxGroup.items) |curBox| {
        const gridX = @as(i32, @intFromFloat(curBox.x));
        const gridY = @as(i32, @intFromFloat(curBox.y));
        if (gridY + 1 >= 9) return false;
        const blockBelow = game.getBlockWorldGrid(gridX, gridY + 1);
        if (blockBelow == sol or blockBelow == frt) return false;
        if (blockBelow == box or blockBelow == bdy) {
            if (!movement.canPush(@intFromFloat(curBox.x), @intFromFloat(curBox.y), direction.down)) return false;
        }
    }
    return true;
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
