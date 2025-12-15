const game = @import("game.zig");
const player = @import("player.zig");
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
pub const direction = player.direction;
var movementLocked = false;
pub var canBoxesFall = false;
const noGroup = error{noGroupFound};
pub var redoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);
pub var undoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);
pub var boxList = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);
var fallingGroups = std.ArrayList(bool).init(std.heap.c_allocator);
const Vec2Hash = struct { x: i32, y: i32 };

pub fn canMoveBox(x: i32, y: i32, dir: player.direction) bool {
    const vec: rl.Vector2 = rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
    const boxGroup = boxGroupAtCoord(vec) catch |err| {
        std.debug.print("box does not exist {}", .{err});
        return false;
    };
    return canGroupMove(boxGroup, dir);
}

pub fn boxGroupAtCoord(coord: rl.Vector2) !std.ArrayList(rl.Vector2) {
    for (boxList.items) |boxGroup| {
        if (boxGroupHasCoord(coord, boxGroup)) return boxGroup;
    }
    return noGroup.noGroupFound;
}

fn boxGroupHasCoord(coord: rl.Vector2, boxGroup: std.ArrayList(rl.Vector2)) bool {
    for (boxGroup.items) |curBox| {
        if (curBox.x == coord.x and curBox.y == coord.y) return true;
    }
    return false;
}

fn canGroupMove(boxGroup: std.ArrayList(rl.Vector2), dir: direction) bool {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var affectedGroups = std.ArrayList(usize).init(allocator);
    var visitedGroups = std.AutoHashMap(usize, void).init(allocator);
    var queue = std.ArrayList(usize).init(allocator);
    var startIndex: ?usize = null;
    for (boxList.items, 0..) |*group, i| {
        if (boxGroupEquals(group.*, boxGroup)) {
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
        for (boxList.items[currentIndex].items) |curBox| {
            const dirVec = directionToOffset(dir);
            const nextX = @as(i32, @intFromFloat(curBox.x)) + dirVec.x;
            const nextY = @as(i32, @intFromFloat(curBox.y)) + dirVec.y;
            const nextBlock = game.getBlockWorldGrid(nextX, nextY);
            if (nextBlock == box) {
                const nextVec = rl.Vector2{ .x = @floatFromInt(nextX), .y = @floatFromInt(nextY) };
                const nextGroup = boxGroupAtCoord(nextVec) catch continue;
                for (boxList.items, 0..) |*groupPtr, i| {
                    if (boxGroupEquals(groupPtr.*, nextGroup)) {
                        if (!visitedGroups.contains(i)) queue.append(i) catch return false;
                        break;
                    }
                }
            }
        }
    }
    var movingPositions = std.AutoHashMap(Vec2Hash, void).init(allocator);
    for (affectedGroups.items) |groupIndex| {
        for (boxList.items[groupIndex].items) |pos| {
            const hashPos = Vec2Hash{ .x = @intFromFloat(pos.x), .y = @intFromFloat(pos.y) };
            movingPositions.put(hashPos, {}) catch return false;
        }
    }
    for (affectedGroups.items) |groupIndex| {
        for (boxList.items[groupIndex].items) |curBox| {
            const dirVec = directionToOffset(dir);
            const nextX = @as(i32, @intFromFloat(curBox.x)) + dirVec.x;
            const nextY = @as(i32, @intFromFloat(curBox.y)) + dirVec.y;
            if (!isDestinationValid(nextX, nextY, &movingPositions)) return false;
        }
    }
    return true;
}

fn boxGroupEquals(a: std.ArrayList(rl.Vector2), b: std.ArrayList(rl.Vector2)) bool {
    if (a.items.len != b.items.len) return false;
    for (a.items) |aBox| {
        var found = false;
        for (b.items) |bBox| {
            if (aBox.x == bBox.x and aBox.y == bBox.y) {
                found = true;
                break;
            }
        }
        if (!found) return false;
    }
    return true;
}

fn directionToOffset(dir: direction) struct { x: i32, y: i32 } {
    return switch (dir) {
        direction.left => .{ .x = -1, .y = 0 },
        direction.right => .{ .x = 1, .y = 0 },
        direction.up => .{ .x = 0, .y = -1 },
        direction.down => .{ .x = 0, .y = 1 },
    };
}

fn isDestinationValid(x: i32, y: i32, movingPositions: *std.AutoHashMap(Vec2Hash, void)) bool {
    const blk = game.getBlockWorldGrid(x, y);
    const pos = Vec2Hash{ .x = x, .y = y };
    if (movingPositions.contains(pos)) return true;
    if (blk == blockType.vic and player.fruitNumber > 0) return false;
    if (blk == air or blk == blockType.vic) return true;
    return false;
}

pub fn posMoveable(x: i32, y: i32, dir: direction) bool {
    const blk = game.getBlockWorldGrid(x, y);
    if (blk == box or blk == bdy) {
        return switch (dir) {
            direction.up => posMoveable(x, y - 1, dir),
            direction.down => posMoveable(x, y + 1, dir),
            direction.left => posMoveable(x - 1, y, dir),
            direction.right => posMoveable(x + 1, y, dir),
        };
    }
    if (blk == blockType.vic and player.fruitNumber > 0) return false;
    if (blk == air or blk == frt or blk == blockType.vic or blk == spk) return true;
    return false;
}

pub fn movePos(vec: rl.Vector2, dir: direction) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var affectedGroups = std.ArrayList(usize).init(allocator);
    var visitedGroups = std.AutoHashMap(usize, void).init(allocator);
    var queue = std.ArrayList(usize).init(allocator);
    var startIndex: ?usize = null;
    for (boxList.items, 0..) |*group, i| {
        if (boxGroupHasCoord(vec, group.*)) {
            startIndex = i;
            break;
        }
    }
    if (startIndex == null) {
        std.debug.print("box group does not exist\n", .{});
        return;
    }
    queue.append(startIndex.?) catch return;
    while (queue.items.len > 0) {
        const currentIndex = queue.orderedRemove(0);
        if (visitedGroups.contains(currentIndex)) continue;
        visitedGroups.put(currentIndex, {}) catch return;
        affectedGroups.append(currentIndex) catch return;
        for (boxList.items[currentIndex].items) |curBox| {
            const dirVec = directionToOffset(dir);
            const nextX = @as(i32, @intFromFloat(curBox.x)) + dirVec.x;
            const nextY = @as(i32, @intFromFloat(curBox.y)) + dirVec.y;
            const nextBlock = game.getBlockWorldGrid(nextX, nextY);
            if (nextBlock == box) {
                const nextVec = rl.Vector2{ .x = @floatFromInt(nextX), .y = @floatFromInt(nextY) };
                const nextGroup = boxGroupAtCoord(nextVec) catch continue;
                for (boxList.items, 0..) |*groupPtr, i| {
                    if (boxGroupEquals(groupPtr.*, nextGroup)) {
                        if (!visitedGroups.contains(i)) queue.append(i) catch return;
                        break;
                    }
                }
            }
        }
    }
    const dirVector = game.directionToVec2(dir);
    for (affectedGroups.items) |groupIndex| {
        for (boxList.items[groupIndex].items) |curBox| game.setBlockWorldGrid(curBox.x, curBox.y, air);
    }
    for (affectedGroups.items) |groupIndex| {
        for (boxList.items[groupIndex].items) |*curBox| {
            curBox.*.x = curBox.x + dirVector.x;
            curBox.*.y = curBox.y + dirVector.y;
        }
    }
    for (affectedGroups.items) |groupIndex| {
        for (boxList.items[groupIndex].items) |curBox| game.setBlockWorldGrid(curBox.x, curBox.y, box);
    }
}

fn canGroupFall(boxGroup: std.ArrayList(rl.Vector2)) bool {
    for (boxGroup.items) |curBox| {
        const gridX = @as(i32, @intFromFloat(curBox.x));
        const gridY = @as(i32, @intFromFloat(curBox.y));
        if (gridY + 1 >= 9) return false;
        const blockBelow = game.getBlockWorldGrid(gridX, gridY + 1);
        if (blockBelow == sol or blockBelow == frt) return false;
        if (blockBelow == box) {
            if (!canGroupMove(boxGroup, direction.down)) return false;
        }
        if (isPlayerAtPosition(@floatFromInt(gridX), @floatFromInt(gridY + 1))) return false;
    }
    return true;
}

fn isPlayerAtPosition(x: f32, y: f32) bool {
    for (player.body.items) |bodyPart| {
        if (bodyPart.x == x and bodyPart.y == y) return true;
    }
    return false;
}

fn fallGroup(groupIndex: usize) void {
    for (boxList.items[groupIndex].items) |*curBox| curBox.*.y += 10 * rl.getFrameTime();
}

pub fn updateBoxGravity() void {
    if (!canBoxesFall) return;
    while (fallingGroups.items.len < boxList.items.len) fallingGroups.append(false) catch return;
    for (boxList.items, 0..) |group, i| {
        const canFall = canGroupFall(group);
        if (canFall) {
            if (!fallingGroups.items[i]) {
                for (group.items) |curBox| game.setBlockWorldGrid(curBox.x, curBox.y, air);
                fallingGroups.items[i] = true;
            }
            fallGroup(i);
        } else {
            if (fallingGroups.items[i]) {
                for (group.items) |*curBox| {
                    curBox.*.y = @floatFromInt(@as(i32, @intFromFloat(curBox.y)));
                    game.setBlockWorldGrid(curBox.x, curBox.y, box);
                }
                fallingGroups.items[i] = false;
            }
        }
    }
}

pub fn clearBoxes() void {
    for (boxList.items) |group| group.deinit();
    boxList.clearAndFree();
    fallingGroups.clearAndFree();
}

pub fn drawBoxes(texture: rl.Texture) void {
    for (boxList.items, 0..) |boxGroup, i| {
        const group: std.ArrayList(rl.Vector2) = boxGroup;
        for (group.items) |curBox| {
            game.drawTexture(
                texture,
                @as(i32, @intFromFloat(curBox.x * @as(f32, @floatFromInt(game.boxSize)))),
                @as(i32, @intFromFloat(curBox.y * @as(f32, @floatFromInt(game.boxSize)))),
                rl.Color.init(@intCast(@divTrunc(255, i + 1)), 255, @intCast(@divTrunc(255, i + 1)), 255),
            );
        }
    }
}
