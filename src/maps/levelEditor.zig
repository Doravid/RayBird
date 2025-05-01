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
var waitingOnInput = false;

const level = struct {
    map: [9][16]blockType,
    player: []player.pos,
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

var userInput: [64:0]u8 = undefined;
var view: bool = true;

pub fn loadLevelEditor() void {
    const text_box = rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(game.boxSize)), .width = 4.0 * @as(f32, @floatFromInt(game.boxSize)), .x = (@as(f32, @floatFromInt(game.screenWidth)) / 2.0) - 240.0, .y = 80 };

    if (rl.isMouseButtonPressed(rl.MouseButton.left) and !waitingOnInput) {
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
            if (!waitingOnInput) {
                waitingOnInput = true;
                return;
            }

            std.debug.print("POS: {}\n", .{x});
        }
    }
    if (waitingOnInput) {
        userInput[0] = 'H';
        const res = gui.guiTextInputBox(text_box, "", "Please enter level name:", "Save;Cancel", &userInput, 64, &view);
        if (res == 1) {
            waitingOnInput = false;
            writeLevelToFile(level.init(player.mat16x9, body.items), userInput);
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

fn writeLevelToFile(level1: level, name: [64:0]u8) void {
    const allocator = std.heap.page_allocator;

    const name_slice = std.mem.sliceTo(&name, 0);
    const name_len = name_slice.len;

    const prefix = "./src/maps/";
    const suffix = ".json";
    const path = allocator.alloc(u8, prefix.len + name_len + suffix.len) catch |err| {
        std.debug.print("Failed to allocate: {}\n", .{err});
        return;
    };
    std.mem.copyForwards(u8, path[0..], prefix);
    std.mem.copyForwards(u8, path[prefix.len..], name[0..name_len]);
    std.mem.copyForwards(u8, path[prefix.len + name_len ..], suffix);

    //Print to file
    const string = json.stringifyAlloc(allocator, level1, .{ .emit_strings_as_arrays = false }) catch |err| {
        std.debug.print("Failed to stringify: {}\n", .{err});
        return;
    };
    var file = fs.cwd().createFile(path, .{}) catch |err| {
        std.debug.print("Failed to createFile: {}\n", .{err});
        return;
    };
    defer file.close();
    _ = file.writeAll(string) catch |err| {
        std.debug.print("Failed to writeAll: {}\n", .{err});
        return;
    };
}
