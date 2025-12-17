const std = @import("std");
const rl = @import("raylib");

const game = @import("game.zig");
const boxes = @import("boxes.zig");
const player = @import("player.zig");

const blockType = game.blockType;
const air = blockType.air;
const sol = blockType.sol;
const box_blk = blockType.box;
const bdy = blockType.bdy;
const frt = blockType.frt;
const spk = blockType.spk;
const vic = blockType.vic;

pub const Direction = player.direction;

pub const Vec2i = struct { x: i32, y: i32 };

pub fn dirOffset(dir: Direction) Vec2i {
    return switch (dir) {
        .left => .{ .x = -1, .y = 0 },
        .right => .{ .x = 1, .y = 0 },
        .up => .{ .x = 0, .y = -1 },
        .down => .{ .x = 0, .y = 1 },
    };
}

const GroupKind = enum { box, player };

const GroupRef = struct {
    kind: GroupKind,
    index: usize,
};

fn groupCells(g: GroupRef) []rl.Vector2 {
    return switch (g.kind) {
        .box => boxes.boxList.items[g.index].items,
        .player => player.playerList.items[g.index].items,
    };
}

fn cellBelongsToGroup(x: i32, y: i32) ?GroupRef {
    const xf = @as(f32, @floatFromInt(x));
    const yf = @as(f32, @floatFromInt(y));

    for (boxes.boxList.items, 0..) |grp, i| {
        for (grp.items) |c| {
            if (c.x == xf and c.y == yf)
                return .{ .kind = .box, .index = i };
        }
    }

    for (player.playerList.items, 0..) |grp, i| {
        for (grp.items) |c| {
            if (c.x == xf and c.y == yf)
                return .{ .kind = .player, .index = i };
        }
    }

    return null;
}

pub fn canPush(startX: i32, startY: i32, dir: Direction) bool {
    const block = game.getBlockWorldGrid((startX), (startY));
    if (block == air or block == frt) return true;
    if (block == vic and player.fruitNumber == 0) return true;
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const startGroup = cellBelongsToGroup(startX, startY) orelse return false;

    var visited = std.AutoHashMap(GroupRef, void).init(allocator);
    var affected = std.ArrayList(GroupRef).init(allocator);
    var queue = std.ArrayList(GroupRef).init(allocator);

    queue.append(startGroup) catch return false;

    const d = dirOffset(dir);

    while (queue.items.len > 0) {
        const g = queue.orderedRemove(0);
        if (visited.contains(g)) continue;

        visited.put(g, {}) catch return false;
        affected.append(g) catch return false;

        for (groupCells(g)) |cell| {
            const nx = @as(i32, @intFromFloat(cell.x)) + d.x;
            const ny = @as(i32, @intFromFloat(cell.y)) + d.y;

            if (nx < 0 or nx >= 16 or ny < 0 or ny >= 9)
                return false;

            const blk = game.getBlockWorldGrid(nx, ny);

            switch (blk) {
                sol, spk => return false,
                vic => if (player.fruitNumber > 0) return false,
                box_blk, bdy => {
                    const nextGroup = cellBelongsToGroup(nx, ny) orelse return false;
                    if (!visited.contains(nextGroup))
                        queue.append(nextGroup) catch return false;
                },
                else => {},
            }
        }
    }

    var moving = std.AutoHashMap(Vec2i, void).init(allocator);

    for (affected.items) |g| {
        for (groupCells(g)) |c| {
            moving.put(.{
                .x = @as(i32, @intFromFloat(c.x)),
                .y = @as(i32, @intFromFloat(c.y)),
            }, {}) catch return false;
        }
    }

    for (affected.items) |g| {
        for (groupCells(g)) |c| {
            const nx = @as(i32, @intFromFloat(c.x)) + d.x;
            const ny = @as(i32, @intFromFloat(c.y)) + d.y;

            if (moving.contains(.{ .x = nx, .y = ny }))
                continue;

            const blk = game.getBlockWorldGrid(nx, ny);
            if (blk != air and blk != vic)
                return false;
        }
    }

    return true;
}

pub fn applyPush(startX: i32, startY: i32, dir: Direction) void {
    if (!canPush(startX, startY, dir)) return;

    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const startGroup = cellBelongsToGroup(startX, startY) orelse return;

    var visited = std.AutoHashMap(GroupRef, void).init(allocator);
    var affected = std.ArrayList(GroupRef).init(allocator);
    var queue = std.ArrayList(GroupRef).init(allocator);

    queue.append(startGroup) catch return;

    const d = dirOffset(dir);
    const dv = rl.Vector2{
        .x = @as(f32, @floatFromInt(d.x)),
        .y = @as(f32, @floatFromInt(d.y)),
    };

    while (queue.items.len > 0) {
        const g = queue.orderedRemove(0);
        if (visited.contains(g)) continue;

        visited.put(g, {}) catch return;
        affected.append(g) catch return;

        for (groupCells(g)) |cell| {
            const nx = @as(i32, @intFromFloat(cell.x)) + d.x;
            const ny = @as(i32, @intFromFloat(cell.y)) + d.y;

            const blk = game.getBlockWorldGrid(nx, ny);
            if (blk == box_blk or blk == bdy) {
                const ng = cellBelongsToGroup(nx, ny) orelse continue;
                if (!visited.contains(ng))
                    queue.append(ng) catch return;
            }
        }
    }

    for (affected.items) |g| {
        for (groupCells(g)) |c|
            game.setBlockWorldGrid(c.x, c.y, air);
    }

    for (affected.items) |g| {
        for (groupCells(g)) |*c| {
            c.*.x += dv.x;
            c.*.y += dv.y;
        }
    }

    for (affected.items) |g| {
        const blk = switch (g.kind) {
            .box => box_blk,
            .player => bdy,
        };

        for (groupCells(g)) |c|
            game.setBlockWorldGrid(c.x, c.y, blk);
    }
}

var fallingBoxes = std.ArrayList(bool).init(std.heap.c_allocator);
var fallingPlayers = std.ArrayList(bool).init(std.heap.c_allocator);

pub fn updateGravity() void {
    const dt = rl.getFrameTime();
    const speed: f32 = 10.0;

    ensureFallArrays();

    for (boxes.boxList.items, 0..) |_, i| {
        handleGravity(.{ .kind = .box, .index = i }, &fallingBoxes.items[i], dt, speed);
    }

    for (player.playerList.items, 0..) |_, i| {
        handleGravity(.{ .kind = .player, .index = i }, &fallingPlayers.items[i], dt, speed);
    }
}
fn ensureFallArrays() void {
    while (fallingBoxes.items.len < boxes.boxList.items.len)
        fallingBoxes.append(false) catch return;

    while (fallingPlayers.items.len < player.playerList.items.len)
        fallingPlayers.append(false) catch return;
}

fn handleGravity(
    g: GroupRef,
    falling: *bool,
    dt: f32,
    speed: f32,
) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const groups = collectAffected(g, .down, arena.allocator());

    // Cannot fall
    if (groups == null or
        !validateMove(groups.?.items, .down, arena.allocator()))
    {
        if (falling.*) {
            snapGroupToGrid(g);
            falling.* = false;
        }
        return;
    }

    if (!falling.*) {
        for (groups.?.items) |gr|
            for (groupCells(gr)) |c|
                game.setBlockWorldGrid(c.x, c.y, blockType.air);
        falling.* = true;
    }

    for (groups.?.items) |gr| {
        for (groupCells(gr)) |*c| {
            c.*.y += speed * dt;
        }
    }
}
fn snapGroupToGrid(g: GroupRef) void {
    const blk = groupBlock(g);

    for (groupCells(g)) |*c| {
        c.*.y = @floatFromInt(@as(i32, @intFromFloat(c.y)));
        game.setBlockWorldGrid(c.x, c.y, blk);
    }
}

fn groupBlock(g: GroupRef) blockType {
    return switch (g.kind) {
        .box => blockType.box,
        .player => blockType.bdy,
    };
}

fn collectAffected(
    start: GroupRef,
    dir: Direction,
    allocator: std.mem.Allocator,
) ?std.ArrayList(GroupRef) {
    var visited = std.AutoHashMap(GroupRef, void).init(allocator);
    var affected = std.ArrayList(GroupRef).init(allocator);
    var queue = std.ArrayList(GroupRef).init(allocator);

    queue.append(start) catch return null;
    const d = dirOffset(dir);

    while (queue.items.len > 0) {
        const g = queue.orderedRemove(0);
        if (visited.contains(g)) continue;

        visited.put(g, {}) catch return null;
        affected.append(g) catch return null;

        for (groupCells(g)) |cell| {
            const nx = @as(i32, @intFromFloat(cell.x)) + d.x;
            const ny = @as(i32, @intFromFloat(cell.y)) + d.y;

            if (nx < 0 or nx >= 16 or ny < 0 or ny >= 9)
                return null;

            const blk = game.getBlockWorldGrid(nx, ny);

            switch (blk) {
                sol, spk => return null,
                vic => if (player.fruitNumber > 0) return null,
                box_blk, bdy => {
                    const ng = cellBelongsToGroup(nx, ny) orelse return null;
                    if (!visited.contains(ng))
                        queue.append(ng) catch return null;
                },
                else => {},
            }
        }
    }

    return affected;
}

fn validateMove(groups: []GroupRef, dir: Direction, allocator: std.mem.Allocator) bool {
    var occupied = std.AutoHashMap(Vec2i, void).init(allocator);
    const d = dirOffset(dir);

    for (groups) |g| {
        for (groupCells(g)) |c| {
            occupied.put(.{
                .x = @as(i32, @intFromFloat(c.x)),
                .y = @as(i32, @intFromFloat(c.y)),
            }, {}) catch return false;
        }
    }

    for (groups) |g| {
        for (groupCells(g)) |c| {
            const nx = @as(i32, @intFromFloat(c.x)) + d.x;
            const ny = @as(i32, @intFromFloat(c.y)) + d.y;

            if (occupied.contains(.{ .x = nx, .y = ny }))
                continue;

            const blk = game.getBlockWorldGrid(nx, ny);
            if (blk != air and blk != vic)
                return false;
        }
    }

    return true;
}
