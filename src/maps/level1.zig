//Header Stuff, All levels must have this.
const game = @import("..\\game.zig");
const player = @import("..\\player.zig");
const rl = @import("raylib");
const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const vic = blockType.vic;
const pos = player.pos;
//End of header stuff.
pub const map = [9][16]blockType{
    [_]blockType{ air, air, air, air, air, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, sol, vic, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ frt, air, air, sol, air, air, air, air, air, air, air, air, air, air, air, vic },
    [_]blockType{ sol, air, air, sol, air, air, air, air, air, air, air, air, air, sol, air, air },
    [_]blockType{ sol, sol, sol, sol, sol, air, air, air, air, air, air, air, air, air, sol, air },
};
//Snake body: [0] is head and [len-1] is tail
pub const snake = [_]pos{ pos{ .x = 0, .y = 0 }, pos{ .x = 120, .y = 0 }, pos{ .x = 240, .y = 0 } };
