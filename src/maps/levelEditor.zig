const game = @import("../game.zig");
const player = @import("../player.zig");
const rl = @import("raylib");
const gui = @import("raygui");
const std = @import("std");
const levelManager = @import("levelManager.zig");
const fs = std.fs;
const json = std.json;

const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
pub var currentBlock: blockType = sol;
var waitingOnInput = false;

pub const emptyMap = [9][16]blockType{
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
pub fn initLevelEditor() void {
    player.mat16x9 = emptyMap;
}
pub var body = std.ArrayList(rl.Vector2).init(std.heap.c_allocator);

var userInput: [64:0]u8 = undefined;
var view: bool = true;

pub fn loadLevelEditor() void {
    const text_box = rl.Rectangle{ .height = 1.25 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .width = 4.0 * @as(f32, @floatFromInt(rl.getScreenWidth())) / 16, .x = (@as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0) - 240.0, .y = 80 };
    if (!waitingOnInput and (rl.isKeyDown(rl.KeyboardKey.left_control) and rl.isKeyDown(rl.KeyboardKey.s))) {
        waitingOnInput = true;
    }
    if (rl.isMouseButtonPressed(rl.MouseButton.left) and !waitingOnInput) {
        const pos = rl.getMousePosition();
        std.debug.print("x: {}, y: {} \n", .{ pos.x, pos.y });
        const replacedBlock = game.getBlockAt(pos.x, pos.y);
        if (currentBlock != bdy) game.setBlockAt(pos.x, pos.y, currentBlock);

        if (currentBlock == bdy and replacedBlock != bdy) {
            const x: i32 = @divTrunc(@as(i32, @intFromFloat(pos.x)), game.boxSize);
            const y: i32 = @divTrunc(@as(i32, @intFromFloat(pos.y)), game.boxSize);
            if (body.items.len == 0 or
                (@abs(x - @as(i32, @intFromFloat(body.items[0].x))) == 1 and @abs(y - @as(i32, @intFromFloat(body.items[0].y))) == 0) or
                (@abs(y - @as(i32, @intFromFloat(body.items[0].y))) == 1 and @abs(x - @as(i32, @intFromFloat(body.items[0].x))) == 0))
            {
                body.insert(0, rl.Vector2{ .x = @as(f32, @floatFromInt(x)), .y = @as(f32, @floatFromInt(y)) }) catch |err| {
                    std.debug.print("Failed to insert/app body: {}\n", .{err});
                    return;
                };
                std.log.debug("vector {}", .{body.items[body.items.len - 1]});
                game.setBlockAt((pos.x), (pos.y), currentBlock);
            }
        }
    }

    if (waitingOnInput) {
        const res = gui.guiTextInputBox(text_box, "Save Level", "Please enter level name:", "Save;Cancel", &userInput, 64, &view);
        if (res == -1) return;
        var i: usize = 0;
        if (res == 1) {
            waitingOnInput = false;
            writeLevelToFile(levelManager.level{ .map = player.mat16x9, .player = body.items }, userInput);
            while (i < 64) {
                userInput[i] = 0;
                i += 1;
            }
        }
        if (res == 2) {
            waitingOnInput = false;
            while (i < 64) {
                userInput[i] = 0;
                i += 1;
            }
        }
    }
    const numBlocks: comptime_int = 6;
    if (rl.getMouseWheelMove() > 0) {
        currentBlock = @enumFromInt(@mod(@intFromEnum(currentBlock) + 1, numBlocks));
    } else if (rl.getMouseWheelMove() < 0) {
        var x = @intFromEnum(currentBlock) - 1;
        if (x < 0) x = numBlocks - 1;
        currentBlock = @enumFromInt(x);
    }
    if (body.items.len > 0) {
        player.drawPlayer(&game.body_textures, body);
    }
}
fn writeLevelToFile(level1: levelManager.level, name: [64:0]u8) void {
    const allocator = std.heap.c_allocator;

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
