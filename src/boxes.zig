const game = @import("game.zig");
const player = @import("player.zig");
const rl = @import("raylib");
const std = @import("std");
const movement = @import("movement.zig");
const levelManager = @import("maps/levelManager.zig");

pub var boxRedoHistory = std.ArrayList(std.ArrayList(std.ArrayList(rl.Vector2))).init(std.heap.c_allocator);
pub var boxUndoHistory = std.ArrayList(std.ArrayList(std.ArrayList(rl.Vector2))).init(std.heap.c_allocator);
pub var boxList = std.ArrayList(std.ArrayList(rl.Vector2)).init(std.heap.c_allocator);

pub fn clearBoxes() void {
    for (boxList.items) |group| group.deinit();
    boxList.clearAndFree();
}
pub fn undo() void {
    if (boxUndoHistory.items.len <= 0) return;
    const oldBody = boxList.clone() catch |err| {
        std.debug.print("Failed to clone playerList: {}\n", .{err});
        return;
    };
    boxRedoHistory.append(oldBody) catch |err| {
        std.debug.print("Failed to append redo history: {}\n", .{err});
        return;
    };
    boxList = boxUndoHistory.pop();
}

pub fn redo() void {
    if (boxRedoHistory.items.len <= 0) return;

    const clone = boxList.clone() catch |err| {
        std.debug.print("Failed to clone body redo: {}\n", .{err});
        return;
    };
    boxUndoHistory.append(clone) catch |err| {
        std.debug.print("Failed to append undo position: {}\n", .{err});
        return;
    };

    boxList = boxRedoHistory.pop();
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
