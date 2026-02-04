const game = @import("game.zig");
const std = @import("std");
const rl = @import("raylib");
const gui = @import("raygui");
const builtin = @import("builtin");

pub fn main() anyerror!void {
    //To set config flags
    const myFlag = rl.ConfigFlags{
        .msaa_4x_hint = true,
    };
    rl.setConfigFlags(myFlag);
    rl.initWindow(1920, 1080, "RayBird");
    if (builtin.target.os.tag != .emscripten) {
        rl.initAudioDevice();
    }
    rl.setTargetFPS(3000);
    rl.setExitKey(rl.KeyboardKey.delete);
    gui.guiSetStyle(gui.GuiControl.default, gui.GuiDefaultProperty.text_size, 30);

    try game.runGame();
}
