//Header Stuff, All levels must have this.
const game = @import("..\\game.zig");
const player = @import("..\\player.zig");
const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const pos = player.pos;

//Level array:
pub const level = [9][16]blockType{
    [_]blockType{ sol, air, air, air, air, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, air, air, air, air, air, sol, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, sol, air, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ frt, air, air, sol, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol },
    [_]blockType{ sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol, sol },
};
//Snake body: [0] is head and [len-1] is tail
pub const snake = []pos{ pos{ .x = 0, .y = 0 }, pos{ .x = 120, .y = 0 }, pos{ .x = 240, .y = 0 } };
