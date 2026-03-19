#+vet explicit-allocators
package src

import "core:c"
import "core:container/small_array"
import "lib:mini/bvh"
import "core:log"
import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"

SCREEN_WIDTH :: 2800
SCREEN_HEIGHT :: 1000
// SCREEN_WIDTH :: 1200
// SCREEN_HEIGHT :: 600

Context :: struct {
        player: ecs.Entity,
        cam:    rl.Camera3D,
        cursor_enabled:  bool,

        models:            [Model_Kind]rl.Model,
}

Model :: struct {
        model: rl.Model, // shared raylib model
        anim_frame: i32,
        anim:       i32,
}

Model_Kind :: enum {
        Double_Barrel,
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
vec4 :: [4]f32

main :: proc() {
        context.logger = log.create_console_logger(.Debug, allocator = context.allocator)
        allocator := context.allocator
        _ctx: Context

        world: ecs.World
        w := &world
        w.userdata = &_ctx

        ctx := ctx(w)
        
        ecs.init(w, {Transform, Player, Movement, Velocity}, allocator)
        ecs.register(w, debug_system)
        ecs.register(w, player_movement_system)
        ecs.register(w, movement_system)
        ecs.register(w, velocity_system)
        ecs.register(w, player_direction_system)
        ecs.register(w, player_camera_system)
        ecs.register(w, player_item_system)

        context.temp_allocator = w.frame_allocator

        player := ecs.create(w)
        player_component := Player{height = 3}
        small_array.append(&player_component.items, Double_Barrel{
                loaded = 2,
                ammo = 60,
        })
        ecs.set(w, player, player_component)
        ecs.set(w, player, Transform{dir = {0, 0, 1}})
        ecs.set(w, player, Velocity{})
        ecs.set(w, player, Movement{speed = PLAYER_SPEED})
        ctx.player = player
        
        rl.SetConfigFlags({.WINDOW_RESIZABLE})
        rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "kidnapper")
        rl.DisableCursor()
        rl.SetTargetFPS(120)

        cam: rl.Camera3D
        cam.up = {0, 1, 0}
        cam.fovy = 80
        cam.projection = .PERSPECTIVE
        cam.target = {0, 0, 0}
        cam.position = {0, 0, -5}
        ctx.cam = cam

        ctx.models = {
                .Double_Barrel = rl.LoadModel("resources/gun/shoot/shoot0044.obj"),
        }

        for !rl.WindowShouldClose() {
                ecs.update(w)

                rl.BeginDrawing()
                rl.ClearBackground(rl.DARKGRAY)
                rl.BeginMode3D(ctx.cam)

                rl.DrawModel(ctx.models[.Double_Barrel], {1, 1, 1}, 1, rl.WHITE)
                rl.DrawModel(ctx.models[.Double_Barrel], {2, 1, 1}, 1, rl.WHITE)

                rl.DrawBoundingBox(rl.GetModelBoundingBox(ctx.models[.Double_Barrel]), rl.RED)

                draw_equipped(w)

                rl.DrawGrid(30, 5)
                rl.DrawCapsuleWires({0, 0, 0}, {4, 4, 4}, 1, 12, 9, rl.GREEN)

                rl.EndMode3D()
                rl.DrawFPS(10, 10)
                rl.EndDrawing()
        }
}
