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
var canFall = false;

pub var redoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);
pub var undoHistory = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);

pub var boxList = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);

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
        if (boxGroupHasCoord(coord, boxGroup)) {
            return boxGroup;
        }
    }
    const noGroup = error{noGroupFound};
    return noGroup.noGroupFound;
}

fn boxGroupHasCoord(coord: rl.Vector2, boxGroup: std.ArrayList(rl.Vector2)) bool {
    for (boxGroup.items) |curBox| {
        if (curBox.x == coord.x and curBox.y == coord.y) {
            return true;
        }
    }
    return false;
}
fn canGroupMove(boxGroup: std.ArrayList(rl.Vector2), dir: direction) bool {
    for (boxGroup.items) |curbox| {
        if (!posMoveable(@intFromFloat(curbox.x), @intFromFloat(curbox.y), dir)) return false;
    }
    return true;
}
pub fn posMoveable(x: i32, y: i32, dir: direction) bool {
    const blk = game.getBlockWorldGrid(x, y);
    if (blk == box) {
        switch (dir) {
            direction.up => return (posMoveable(x, y - 1, dir)),
            direction.down => return (posMoveable(x, y + 1, dir)),
            direction.left => return (posMoveable(x - 1, y, dir)),
            direction.right => return (posMoveable(x + 1, y, dir)),
        }
    }
    if (blk == blockType.vic and player.fruitNumber > 0) {
        return false;
    }
    if (blk == air or blk == frt or blk == blockType.vic or blk == spk) {
        return true;
    }
    return false;
}

pub fn movePos(vec: rl.Vector2, dir: direction) void {
    const boxGroup = boxGroupAtCoord(vec) catch |err| {
        std.debug.print("box group does not exist {}\n", .{err});
        return;
    };
    const dirVector = game.directionToVec2(dir);

    for (boxGroup.items) |*curBox| {
        std.debug.print("test: curBox.x {} curBox.y: {} dir: {}\n", .{ curBox.x, curBox.y, dirVector });
        game.setBlockWorldGrid(curBox.x, curBox.y, air);
        curBox.*.x = curBox.x + dirVector.x;
        curBox.*.y = curBox.y + dirVector.y;
        std.debug.print("after: curBox.x {} curBox.y: {} dir: {}\n\n", .{ curBox.x, curBox.y, dirVector });
        // std.debug.print("after: curBox.x {} curBox.y: {}\n\n", .{});
    }
    for (boxGroup.items) |curBox| {
        game.setBlockWorldGrid(curBox.x, curBox.y, box);
    }
}
