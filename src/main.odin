#+vet explicit-allocators
package src

import "core:log"
import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

Context :: struct {
        player: ecs.Entity,
        cam:    rl.Camera3D,
        cursor_enabled:  bool,
}

ctx :: proc(w: ^ecs.World) -> ^Context {
        return (^Context)(w.userdata)
}

Transform :: struct {
        pos: vec3,
        dir: vec3, // local

        yaw:   f32,
        pitch: f32,
}

vec2 :: [2]f32
vec3 :: [3]f32

main :: proc() {
        context.logger = log.create_console_logger(.Debug, allocator = context.allocator)
        allocator := context.allocator
        _ctx: Context

        world: ecs.World
        w := &world
        w.userdata = &_ctx
        
        ecs.init(w, {Transform, Player, Movement, Velocity}, allocator)
        ecs.register(w, debug_system)
        ecs.register(w, player_camera_system)
        ecs.register(w, player_direction_system)
        ecs.register(w, player_movement_system)
        ecs.register(w, movement_system)
        ecs.register(w, velocity_system)

        player := ecs.create(w)
        ecs.set(w, player, Player{height = 3})
        ecs.set(w, player, Transform{dir = {0, 0, 1}})
        ecs.set(w, player, Velocity{})
        ecs.set(w, player, Movement{speed = PLAYER_SPEED})
        ctx(w).player = player
        
        rl.SetConfigFlags({.WINDOW_RESIZABLE})
        rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "kidnapper")
        rl.DisableCursor()
        rl.SetTargetFPS(100)

        cam: rl.Camera3D
        cam.up = {0, 1, 0}
        cam.fovy = 80
        cam.projection = .PERSPECTIVE
        cam.target = {0, 0, 0}
        cam.position = {0, 0, -5}
        ctx(w).cam = cam

        body := rl.LoadModel("resources/body.obj")
        body_pos: rl.Vector3 = {4, 2, 2}
        gun := rl.LoadModel("resources/gun.obj")
        gun_pos: rl.Vector3

        for !rl.WindowShouldClose() {
                ecs.update(w)

                rl.BeginDrawing()
                rl.ClearBackground(rl.DARKGRAY)
                rl.BeginMode3D(ctx(w).cam)

                body.transform = rl.MatrixTranslate(body_pos.x, body_pos.y, body_pos.z)

                rl.DrawModel(body, body_pos, 1, rl.WHITE)
                rl.DrawBoundingBox(rl.GetModelBoundingBox(body), rl.RED)
                rl.DrawModel(gun, gun_pos, 1, rl.WHITE)
                rl.DrawBoundingBox(rl.GetModelBoundingBox(gun), rl.RED)

                rl.DrawGrid(30, 5)

                rl.EndMode3D()
                rl.EndDrawing()
        }
}
