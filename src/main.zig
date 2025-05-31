const std = @import("std");
const rl = @import("raylib");
const rand = std.crypto.random;
const ArrayList = std.ArrayList;

const Laser = struct {
    texture: rl.Texture,
    position: rl.Vector2,
    isGone: bool,

    pub fn init(texturePath: [:0]const u8, init_x: c_int, init_y: c_int) !Laser {
        return Laser{ .texture = try rl.loadTexture(texturePath), .position = rl.Vector2{ .x = @floatFromInt(init_x), .y = @floatFromInt(init_y) }, .isGone = false };
    }

    pub fn deinit(self: *Laser) void {
        rl.unloadTexture(self.texture);
    }

    // TODO: Add collision detection with enemy
    pub fn laserMove(self: *Laser, laserSpeed: f32, deltaTime: f32) void {
        if (self.isGone) return;

        self.position.y -= laserSpeed * deltaTime;

        if (self.position.y == 0) {
            self.isGone = true;
        }
    }

    pub fn draw(self: *Laser) void {
        if (!self.isGone) {
            rl.drawTextureEx(self.texture, self.position, 0.0, 0.2, rl.Color.white);
        }
    }
};

const Enemy = struct {
    texture: rl.Texture,
    position: rl.Vector2,
    screenHeight: c_int,
    isDead: bool,

    pub fn init(texturePath: [:0]const u8, screenWidth: c_int, screenHeight: c_int) !Enemy {
        return Enemy{
            .texture = try rl.loadTexture(texturePath),
            .position = rl.Vector2{ .x = @floatFromInt(rand.intRangeAtMost(c_int, 0, screenWidth)), .y = 5 },
            .screenHeight = screenHeight,
            .isDead = false,
        };
    }

    pub fn deinit(self: *Enemy) void {
        rl.unloadTexture(self.texture);
    }

    pub fn draw(self: Enemy) void {
        if (!self.isDead) {
            rl.drawTextureV(self.texture, self.position, rl.Color.white);
        }
    }

    pub fn enemyMove(self: *Enemy, enemySpeed: f32, deltaTime: f32) void {
        if (self.isDead) return;

        self.position.y += enemySpeed * deltaTime;

        if (self.position.y > @as(f32, @floatFromInt(self.screenHeight - self.texture.height))) {
            self.isDead = true;
        }
    }
};

const SpaceShip = struct {
    texture: rl.Texture,
    position: rl.Vector2,
    screenHeight: c_int,
    screenWidth: c_int,

    pub fn init(texturePath: [:0]const u8, swidth: c_int, sheight: c_int) !SpaceShip {
        return SpaceShip{
            .texture = try rl.loadTexture(texturePath),
            .position = rl.Vector2{ .x = 400, .y = 400 },
            .screenHeight = sheight,
            .screenWidth = swidth,
        };
    }

    pub fn deinit(self: *SpaceShip) void {
        rl.unloadTexture(self.texture);
    }

    pub fn draw(self: SpaceShip) void {
        rl.drawTextureV(self.texture, self.position, rl.Color.white);
    }

    pub fn moveLeft(self: *SpaceShip, playerSpeed: f32, deltaTime: f32) void {
        self.position.x -= playerSpeed * deltaTime;

        if (self.position.x > @as(f32, @floatFromInt(self.screenWidth - self.texture.width))) {
            self.position.x = @as(f32, @floatFromInt(self.screenWidth - self.texture.width));
        }

        if (self.position.x < 0) self.position.x = 0;
    }

    pub fn moveRight(self: *SpaceShip, playerSpeed: f32, deltaTime: f32) void {
        self.position.x += playerSpeed * deltaTime;

        if (self.position.x > @as(f32, @floatFromInt(self.screenWidth - self.texture.width))) {
            self.position.x = @as(f32, @floatFromInt(self.screenWidth - self.texture.width));
        }

        if (self.position.x < 0) self.position.x = 0;
    }

    pub fn shootLaser(self: *SpaceShip, laserTexturePath: [:0]const u8, laserSlice: *ArrayList(Laser)) !void {
        const laserBullet = try Laser.init(laserTexturePath, @intFromFloat(self.position.x), @intFromFloat(self.position.y));
        try laserSlice.append(laserBullet);
    }
};

fn updateLasers(laserList: *ArrayList(Laser), laserSpeed: f32, deltaTime: f32) void {
    for (laserList.items) |*laser| {
        laser.laserMove(laserSpeed, deltaTime);
    }

    var i: usize = 0;
    while (i < laserList.items.len) {
        if (laserList.items[i].isGone) {
            var laser = laserList.orderedRemove(i);
            laser.deinit();
        } else {
            i += 1;
        }
    }
}

fn checkCollision(laser: Laser, enemy: Enemy) bool {
    const laser_rect = rl.Rectangle{
        .x = laser.position.x,
        .y = laser.position.y,
        .width = @floatFromInt(laser.texture.width),
        .height = @floatFromInt(laser.texture.height),
    };

    const enemy_rect = rl.Rectangle{
        .x = enemy.position.x,
        .y = enemy.position.y,
        .width = @floatFromInt(enemy.texture.width),
        .height = @floatFromInt(enemy.texture.height),
    };

    return rl.checkCollisionRecs(laser_rect, enemy_rect);
}

fn processCollisions(laserList: *ArrayList(Laser), enemyList: *ArrayList(Enemy)) void {
    for (laserList.items) |*laser| {
        if (laser.isGone) continue;
        for (enemyList.items) |*enemy| {
            if (enemy.isDead) continue;

            if (checkCollision(laser.*, enemy.*)) {
                laser.isGone = true;
                enemy.isDead = true;
            }
        }
    }
}

fn drawLasers(laserList: *ArrayList(Laser)) void {
    for (laserList.items) |*laser| {
        laser.draw();
    }
}

fn updateEnemy(enemyList: *ArrayList(Enemy), enemySpeed: f32, deltaTime: f32) void {
    for (enemyList.items) |*enemy| {
        enemy.enemyMove(enemySpeed, deltaTime);
    }

    var i: usize = 0;
    while (i < enemyList.items.len) {
        if (enemyList.items[i].isDead) {
            var enemy = enemyList.orderedRemove(i);
            enemy.deinit();
        } else {
            i += 1;
        }
    }
}

fn drawEnemy(enemyList: *ArrayList(Enemy)) void {
    for (enemyList.items) |*enemy| {
        enemy.draw();
    }
}

fn generateEnemy(n: usize, enemyList: *ArrayList(Enemy), texturePath: [:0]const u8, width: c_int, height: c_int) !void {
    for (0..n) |_| {
        const enemy = try Enemy.init(texturePath, width, height);
        try enemyList.append(enemy);
    }
}

pub fn main() !void {
    const screenWidth: c_int = 800;
    const screenHeight: c_int = 450;
    const playerSpeed: c_int = 200;
    const laserSpeed: c_int = 500;
    const enemySpeed: c_int = 50;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var laserList = ArrayList(Laser).init(allocator);
    defer {
        for (laserList.items) |*laser| {
            laser.deinit();
        }
        laserList.deinit();
    }

    var enemyList = ArrayList(Enemy).init(allocator);
    defer {
        for (enemyList.items) |*enemy| {
            enemy.deinit();
        }
        enemyList.deinit();
    }

    rl.initWindow(screenWidth, screenHeight, "Space Invaders");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var spaceship = try SpaceShip.init("assets/Ship_2.png", screenWidth, screenHeight);
    defer spaceship.deinit();

    while (!rl.windowShouldClose()) {
        const deltaTime = rl.getFrameTime();

        if (rl.isKeyDown(.left)) {
            spaceship.moveLeft(playerSpeed, deltaTime);
        }

        if (rl.isKeyDown(.right)) {
            spaceship.moveRight(playerSpeed, deltaTime);
        }

        if (rl.isKeyDown(.space)) {
            try spaceship.shootLaser("assets/laserBullet.png", &laserList);
        }

        try generateEnemy(1, &enemyList, "assets/Ship_3.png", screenWidth, screenHeight);
        processCollisions(&laserList, &enemyList);
        updateEnemy(&enemyList, enemySpeed, deltaTime);
        updateLasers(&laserList, laserSpeed, deltaTime);

        std.debug.print("Length of enemy list: {}\n", .{enemyList.items.len});

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        spaceship.draw();
        drawLasers(&laserList);
        drawEnemy(&enemyList);

        rl.drawFPS(10, 10);
    }
}
