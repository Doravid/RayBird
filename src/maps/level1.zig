const game = @import("..\\game.zig");
const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
pub const level = [9][16]blockType{
    [_]blockType{ air, air, air, air, air, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, air, sol, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ air, air, air, sol, air, sol, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ frt, air, air, sol, air, air, air, air, air, air, air, air, air, air, air, air },
    [_]blockType{ sol, air, air, sol, air, air, air, air, air, air, air, air, air, sol, air, air },
    [_]blockType{ sol, sol, sol, sol, sol, air, air, air, air, air, air, air, air, air, sol, air },
};
