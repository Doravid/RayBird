const game = @import("..\\game.zig");
const player = @import("..\\player.zig");
const rl = @import("raylib");
const gui = @import("raygui");
const std = @import("std");
const fs = std.fs;
const json = std.json;

const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const nul = blockType.null;

pub var currentBlock: blockType = sol;

const level = struct {
    map: [9][16]blockType,
    player: []player.pos,

    /// Initializes a new Person with the given name, age, and height.
    const Self = @This();
    pub fn init(map: [9][16]blockType, playerA: []player.pos) Self {
        return .{ .map = map, .player = playerA };
    }
};

pub const emptyMap = [9][16]blockType{
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
pub fn initLevelEditor() void {
    player.mat16x9 = emptyMap;
}
var body = std.ArrayList(player.pos).init(std.heap.page_allocator);

pub fn loadLevelEditor() void {
    if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
        const pos = rl.getMousePosition();
        const replacedBlock = game.getBlockAt(@intFromFloat(pos.x), @intFromFloat(pos.y));
        if (currentBlock == nul and replacedBlock == bdy) {}
        game.setBlockAt(@intFromFloat(pos.x), @intFromFloat(pos.y), currentBlock);
        if (currentBlock == bdy and replacedBlock != bdy) {
            const x = @as(i32, @intFromFloat(pos.x / 120)) * 120;
            const y = @as(i32, @intFromFloat(pos.y / 120)) * 120;

            body.append(player.pos{ .x = x, .y = y }) catch |err| {
                std.debug.print("Failed to append position: {}\n", .{err});
                return;
            };
            const level1 = level.init(player.mat16x9, body.items);

            const allocator = std.heap.page_allocator;

            //Print to file
            const string = json.stringifyAlloc(allocator, level1, .{ .emit_strings_as_arrays = false }) catch |err| {
                std.debug.print("Failed to append position: {}\n", .{err});
                return;
            };
            var file = fs.cwd().createFile("./src/maps/level1.json", .{}) catch |err| {
                std.debug.print("Failed to append position: {}\n", .{err});
                return;
            };
            defer file.close();
            _ = file.writeAll(string) catch |err| {
                std.debug.print("Failed to append position: {}\n", .{err});
                return;
            };

            std.debug.print("POS: {}\n", .{x});
        }
    }
    const numBlocks: comptime_int = 5;
    if (rl.getMouseWheelMove() > 0) {
        currentBlock = @enumFromInt(@mod(@intFromEnum(currentBlock) + 1, 5));
    } else if (rl.getMouseWheelMove() < 0) {
        var x = @intFromEnum(currentBlock) - 1;
        if (x < 0) x = numBlocks - 1;
        currentBlock = @enumFromInt(x);
    }
}
