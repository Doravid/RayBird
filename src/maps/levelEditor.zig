const game = @import("..\\game.zig");
const player = @import("..\\player.zig");
const rl = @import("raylib");
const blockType = game.blockType;
const sol = blockType.sol;
const air = blockType.air;
const spk = blockType.spk;
const bdy = blockType.bdy;
const frt = blockType.frt;
const nul = blockType.null;

var currentBlock: blockType = sol;

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
pub fn loadLevelEditor() void {
    if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
        const pos = rl.getMousePosition();
        game.setBlockAt(@intFromFloat(pos.x), @intFromFloat(pos.y), currentBlock);
    }
}
