const std = @import("std");
const rl = @import("raylib");

pub fn main() void {
    const screenWidth: c_int = 800;
    const screenHeight: c_int = 450;

    rl.initWindow(screenWidth, screenHeight, "My First Raylib Window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        rl
    }
}