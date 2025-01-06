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
const boxSize = 120;

//Level array:
pub const map = [9][16]blockType{
    [_]blockType{ air, air, air, air, air, sol, air, air, air, air, air, air, air, air, air, air },
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
pub const snake = [_]pos{ pos{ .x = boxSize * 5, .y = 0 }, pos{ .x = boxSize * 4, .y = 0 }, pos{ .x = boxSize * 4, .y = boxSize * 1 } };
