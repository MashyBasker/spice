const std = @import("std");
const rl = @import("raylib");
const rand = std.crypto.random;
const ArrayList = std.ArrayList;

const Laser = struct {
    texture: rl.Texture,
    position: rl.Vector2,
    isDead: bool,
    reachedEnd: bool,

    pub fn init(texture: rl.Texture, init_x: c_int, init_y: c_int) Laser {
        return Laser{ .texture = texture, .position = rl.Vector2{ .x = @floatFromInt(init_x), .y = @floatFromInt(init_y) }, .isDead = false, .reachedEnd = false };
    }

    pub fn laserMove(self: *Laser, laserSpeed: f32, deltaTime: f32) void {
        if (self.isDead) return;

        self.position.y -= laserSpeed * deltaTime;

        if (self.position.y < @as(f32, @floatFromInt(self.texture.height))) {
            self.reachedEnd = true;
        }
    }

    pub fn draw(self: *Laser) void {
        if (!self.isDead) {

            rl.drawTextureEx(self.texture, self.position, 0.0, 0.2, rl.Color.white);
        }
    }
};

const Enemy = struct {
    texture: rl.Texture,
    position: rl.Vector2,
    screenHeight: c_int,
    isDead: bool,
    reachedEnd: bool,

    pub fn init(texture: rl.Texture, screenWidth: c_int, screenHeight: c_int) Enemy {
        return Enemy{
            .texture = texture,
            .position = rl.Vector2{ .x = @floatFromInt(rand.intRangeAtMost(c_int, 0, screenWidth)), .y = 5 },
            .screenHeight = screenHeight,
            .isDead = false,
            .reachedEnd = false,
        };
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
            self.reachedEnd = true;
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

    pub fn shootLaser(self: *SpaceShip, laserTexture: rl.Texture, laserSlice: *ArrayList(Laser)) !void {
        const laserBullet = Laser.init(laserTexture, @intFromFloat(self.position.x), @intFromFloat(self.position.y));
        try laserSlice.append(laserBullet);
    }
};

fn updateLasers(laserList: *ArrayList(Laser), laserSpeed: f32, deltaTime: f32) void {
    for (laserList.items) |*laser| {
        laser.laserMove(laserSpeed, deltaTime);
    }

    var i: usize = 0;
    while (i < laserList.items.len) {
        if (laserList.items[i].isDead or laserList.items[i].reachedEnd) {
            _ = laserList.orderedRemove(i);
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

fn processCollisions(laserList: *ArrayList(Laser), enemyList: *ArrayList(Enemy), explosionSound: rl.Sound) void {
    for (laserList.items) |*laser| {
        if (laser.isDead) continue;
        for (enemyList.items) |*enemy| {
            if (enemy.isDead) continue;

            if (checkCollision(laser.*, enemy.*)) {
                laser.isDead = true;
                enemy.isDead = true;
                rl.setSoundPitch(explosionSound, 2.0);
                rl.playSound(explosionSound);
                break;
            }
        }
    }
}

fn checkGameOver(enemyList: *ArrayList(Enemy)) bool {
    for (enemyList.items) |*enemy| {
        if(enemy.reachedEnd) {
            return true;
        }
    }
    return false;
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
            _ = enemyList.orderedRemove(i);
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

fn generateEnemy(n: usize, enemyList: *ArrayList(Enemy), texture: rl.Texture, width: c_int, height: c_int) !void {
    for (0..n) |_| {
        const enemy = Enemy.init(texture, width, height);
        try enemyList.append(enemy);
    }
}

pub fn main() !void {
    const screenWidth: c_int = 800;
    const screenHeight: c_int = 450;
    const playerSpeed: c_int = 200;
    const laserSpeed: c_int = 500;
    const enemySpeed: c_int = 50;
    const SPAWN_INTERVAL: f32 = 1.5;
    var spawnTimer: f32 = 0.0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var laserList = ArrayList(Laser).init(allocator);
    defer laserList.deinit();

    var enemyList = ArrayList(Enemy).init(allocator);
    defer enemyList.deinit();


    rl.initWindow(screenWidth, screenHeight, "Space Invaders");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    rl.setTargetFPS(60);

    const shootSound: rl.Sound = try rl.loadSound("assets/laser.wav");
    defer rl.unloadSound(shootSound);

    const explosionSound: rl.Sound = try rl.loadSound("assets/explosion.wav");
    defer rl.unloadSound(explosionSound);

    var spaceship = try SpaceShip.init("assets/Ship_2.png", screenWidth, screenHeight);
    defer spaceship.deinit();

    const laserTexture = try rl.loadTexture("assets/laserBullet.png");
    const enemyTexture = try rl.loadTexture("assets/Ship_3.png");



    main_loop: while(!rl.windowShouldClose()){
        while(!rl.windowShouldClose()) {
            if(rl.isKeyPressed(.enter)) {
                break;
            }

            rl.beginDrawing();
            defer rl.endDrawing();
            rl.drawText("Press Enter to start", 280, 200, 24, rl.Color.white);
        }

        while (!rl.windowShouldClose()) {
            const deltaTime = rl.getFrameTime();

            if (rl.isKeyDown(.left)) {
                spaceship.moveLeft(playerSpeed, deltaTime);
            }

            if (rl.isKeyDown(.right)) {
                spaceship.moveRight(playerSpeed, deltaTime);
            }

            if (rl.isKeyPressed(.space)) {
                try spaceship.shootLaser(laserTexture, &laserList);
                rl.setSoundPitch(shootSound, 2.0);
                rl.playSound(shootSound);
            }

            spawnTimer += deltaTime;
            if(spawnTimer >= SPAWN_INTERVAL) {
                try generateEnemy(1, &enemyList, enemyTexture, screenWidth, screenHeight);
                spawnTimer = 0.0;
            }
            processCollisions(&laserList, &enemyList, explosionSound);
            updateEnemy(&enemyList, enemySpeed, deltaTime);
            updateLasers(&laserList, laserSpeed, deltaTime);

            if(checkGameOver(&enemyList)) {
                break;
            }

            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(rl.Color.black);

            spaceship.draw();
            drawLasers(&laserList);
            drawEnemy(&enemyList);

            rl.drawFPS(10, 10);
        }

        while(!rl.windowShouldClose()) {
            if(rl.isKeyPressed(.escape)) {
                break :main_loop;
            }

            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.black);
            rl.drawText("GAME OVER", 250, 200, 48, rl.Color.red);
            rl.drawText("Press ESC to quit", 280, 300, 24, rl.Color.white);
        }
    }
}
