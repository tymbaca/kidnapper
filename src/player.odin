#+vet explicit-allocators
package src

import "core:time"
import "core:math"
import "core:log"
import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"

UP :: vec3{0, 1, 0}

Player :: struct {
        height: f32,
        state:  Player_State,
        state_started: time.Tick,
}

Player_State :: enum {
        Idle,
        Running,
}

Velocity :: distinct vec3

Movement :: struct {
        desired: vec3,
        speed: f32,
}

PLAYER_SPEED :: 70

player_camera_system :: proc(w: ^ecs.World) {
        ctx := ctx(w)
        trans := ecs.get(w, ctx.player, Transform)
        player := ecs.get(w, ctx.player, Player)

        pos := trans.pos
        pos.y += player.height
        ctx.cam.position = pos
        ctx.cam.up = UP
        ctx.cam.target = pos + trans.dir
}

MOUSE_SENSITIVITY :: 0.4

debug_system :: proc(w: ^ecs.World) {
        ctx := ctx(w)
        if rl.IsKeyPressed(.BACKSLASH) {
                ctx.cursor_enabled = !ctx.cursor_enabled
                
                if ctx.cursor_enabled {
                        rl.EnableCursor()
                } else {
                        rl.DisableCursor()
                }
        }
}

player_direction_system :: proc(w: ^ecs.World) {
        ctx := ctx(w)
        if ctx.cursor_enabled {
                return
        }

        delta := rl.GetMouseDelta()

        e := ctx.player
        trans := ecs.get(w, e, Transform)

        trans.yaw = math.wrap(trans.yaw - delta.x * MOUSE_SENSITIVITY, 360)
        trans.pitch = linalg.clamp((trans.pitch - delta.y * MOUSE_SENSITIVITY), -80, 80)

        pitch := math.to_radians(trans.pitch)
        yaw := math.to_radians(trans.yaw)

        xz_len := math.cos(pitch)
        x := xz_len * math.cos(yaw)
        y := math.sin(pitch)
        z := xz_len * math.sin(-yaw)
        trans.dir = {x, y, z}

        // right := linalg.cross(trans.dir, UP)
        // yaw := linalg.matrix3_rotate_f32(linalg.to_radians(-delta.x), UP)
        // pitch := linalg.matrix3_rotate_f32(linalg.to_radians(-delta.y), right)
        // trans.dir = yaw * pitch * trans.dir

        ecs.set(w, e, trans)
}

player_movement_system :: proc(w: ^ecs.World) {
        e := ctx(w).player
        trans := ecs.get(w, e, Transform)
        player := ecs.get(w, e, Player)
        movement := ecs.get(w, e, Movement)

        flat_dir := trans.dir
        flat_dir.y = 0
        flat_dir = linalg.normalize(flat_dir)

        mov: vec3
        if rl.IsKeyDown(.W) {
                mov += flat_dir
        }
        if rl.IsKeyDown(.S) {
                mov -= flat_dir
        }
        if rl.IsKeyDown(.D) {
                mov += linalg.cross(flat_dir, UP)
        }
        if rl.IsKeyDown(.A) {
                mov -= linalg.cross(flat_dir, UP)
        }

        mov = linalg.normalize0(mov)

        if rl.IsKeyDown(.W) && rl.IsKeyDown(.LEFT_SHIFT) {
                mov *= 2
        }

        movement.desired = mov

        if mov == {} && player.state != .Idle {
                player.state = .Idle
                player.state_started = time.tick_now()
        }
        if mov != {} && player.state != .Running {
                player.state = .Running
                player.state_started = time.tick_now()
        }

        ecs.set(w, e, movement)
        ecs.set(w, e, player)
}

movement_system :: proc(w: ^ecs.World) {
        for e in ecs.query(w, {Movement, Velocity}) {
                mov := ecs.get(w, e, Movement)
                vel := ecs.get(w, e, Velocity)

                vel += auto_cast mov.desired * mov.speed * w.delta

                ecs.set(w, e, vel)
        }
}

velocity_system :: proc(w: ^ecs.World) {
        for e in ecs.query(w, {Transform, Velocity}) {
                trans := ecs.get(w, e, Transform)
                vel := ecs.get(w, e, Velocity)

                trans.pos += auto_cast vel * w.delta
                vel /= 1 + (8 * w.delta)

                ecs.set(w, e, trans)
                ecs.set(w, e, vel)
        }
}
