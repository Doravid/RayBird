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
        std.debug.print("vec: {}\n\n", .{curbox});
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
    }
    for (boxGroup.items) |curBox| {
        game.setBlockWorldGrid(curBox.x, curBox.y, box);
    }
}

var fallingGroups = std.ArrayList(bool).init(std.heap.c_allocator);

// fn canGroupFall(boxGroup: std.ArrayList(rl.Vector2)) bool {
//     return canGroupMove(boxGroup, direction.down);
// }

fn canGroupFall(boxGroup: std.ArrayList(rl.Vector2)) bool {
    for (boxGroup.items) |curBox| {
        const gridX = @as(i32, @intFromFloat(curBox.x));
        const gridY = @as(i32, @intFromFloat(curBox.y));

        if (gridY + 1 >= 9) return false;

        const blockBelow = game.getBlockWorldGrid(gridX, gridY + 1);

        if (blockBelow == sol or blockBelow == frt) return false;

        if (blockBelow == box) {
            if (!posMoveable(gridX, gridY + 1, direction.down)) return false;
        }

        if (isPlayerAtPosition(@floatFromInt(gridX), @floatFromInt(gridY + 1))) {
            return false;
        }
    }
    return true;
}
fn isPlayerAtPosition(x: f32, y: f32) bool {
    for (player.body.items) |bodyPart| {
        if (bodyPart.x == x and bodyPart.y == y) {
            return true;
        }
    }
    return false;
}
fn fallGroup(groupIndex: usize) void {
    for (boxList.items[groupIndex].items) |*curBox| {
        curBox.*.y += 10 * rl.getFrameTime();
    }
}

pub fn updateBoxGravity() void {
    while (fallingGroups.items.len < boxList.items.len) {
        fallingGroups.append(false) catch return;
    }

    for (boxList.items, 0..) |group, i| {
        const canFall = canGroupFall(group);

        if (canFall) {
            if (!fallingGroups.items[i]) {
                for (group.items) |curBox| {
                    game.setBlockWorldGrid(curBox.x, curBox.y, air);
                }
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
    for (boxList.items) |group| {
        group.deinit();
    }
    boxList.clearAndFree();
    fallingGroups.clearAndFree();
}
pub fn drawBoxes(texture: rl.Texture) void {
    for (boxList.items) |boxGroup| {
        const group: std.ArrayList(rl.Vector2) = boxGroup;
        for (group.items) |curBox| {
            game.drawTexture(texture, @as(i32, @intFromFloat(curBox.x * @as(f32, @floatFromInt(game.boxSize)))), @as(i32, @intFromFloat(curBox.y * @as(f32, @floatFromInt(game.boxSize)))), rl.Color.white);
        }
    }
}
