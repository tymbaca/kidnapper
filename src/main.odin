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

Context :: struct {
        player: ecs.Entity,
        cam:    rl.Camera3D,
        cursor_enabled:  bool,

        models:            [Model_Kind]rl.Model,
        model_anim_counts: [Model_Kind]i32,
        model_anims:       [Model_Kind][^]rl.ModelAnimation,
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

        body := rl.LoadModel("resources/body.obj")
        body_pos: rl.Vector3 = {4, 2, 2}
        gun := rl.LoadModel("resources/gun.obj")
        gun_pos: rl.Vector3
        ctx.models = {
                .Double_Barrel = rl.LoadModel("resources/gun.m3d"),
        }

        ctx.model_anims = {
                .Double_Barrel = rl.LoadModelAnimations("resources/gun.m3d", &ctx.model_anim_counts[.Double_Barrel]),
        }

        anim_count: c.int
        anims := rl.LoadModelAnimations("resources/gun.m3d", &anim_count)

        anim_index :: 0
        anim_frame: i32

        for !rl.WindowShouldClose() {
                anim_frame = (anim_frame + 1) % anims[anim_index].frameCount

                ecs.update(w)

                rl.UpdateModelAnimation(ctx.models[.Double_Barrel], anims[anim_index], anim_frame)

                rl.BeginDrawing()
                rl.ClearBackground(rl.DARKGRAY)
                rl.BeginMode3D(ctx.cam)

                body.transform = rl.MatrixTranslate(body_pos.x, body_pos.y, body_pos.z)

                rl.DrawModel(ctx.models[.Double_Barrel], body_pos, 1, rl.WHITE)
                rl.DrawBoundingBox(rl.GetModelBoundingBox(body), rl.RED)
                rl.DrawModel(gun, gun_pos, 1, rl.WHITE)
                rl.DrawBoundingBox(rl.GetModelBoundingBox(gun), rl.RED)

                draw_equipped(w)

                rl.DrawGrid(30, 5)
                rl.DrawCapsuleWires({0, 0, 0}, {4, 4, 4}, 1, 12, 9, rl.GREEN)

                rl.EndMode3D()
                rl.DrawFPS(10, 10)
                rl.EndDrawing()
        }
}
