#+vet explicit-allocators
package src

import "core:math/ease"
import "core:container/small_array"
import "core:time"
import "core:math"
import "core:log"
import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"

UP :: vec3{0, 1, 0}

Player :: struct {
        camera_offset: vec3,
        height: f32,
        mov_state:  Movement_State,
        mov_state_started: time.Tick,

        items:        small_array.Small_Array(20, Inventory_Item),
        current_item: int,
        item_dir:     vec3, // for smooth animation
}

Inventory_Item :: union {
        Gun,
}

Gun :: union {
        Double_Barrel,
}

Double_Barrel :: struct {
        loaded: int,
        ammo: int,
}

Movement_State :: enum {
        Idle,
        Running,
}

Velocity :: distinct vec3

Movement :: struct {
        desired: vec3,
        speed: f32,
}

PLAYER_SPEED :: 70

PLAYER_ITEM_ROTATION_SPEED :: 10

player_camera_system :: proc(w: ^ecs.World) {
        ctx := ctx(w)
        trans := ecs.get(w, ctx.player, Transform)
        player := ecs.get(w, ctx.player, Player)

        log.debug(player.mov_state, "started", time.tick_since(player.mov_state_started), "ago")
        if player.mov_state == .Running {
                from_start := f32(time.duration_seconds(time.tick_since(player.mov_state_started))) * 10
                // player.camera_offset.y += math.sin(from_start) * w.delta * 2
                player.camera_offset = right(trans.dir) * (math.sin(from_start) * 0.03)
                player.camera_offset += UP * (math.sin(from_start) * 0.1)
        } else {
                player.camera_offset /= 1 + (8 * w.delta)
        }

        if player.item_dir == {} {
                player.item_dir = trans.dir
        } 

        if !rl.IsKeyDown(.LEFT_ALT){
                player.item_dir = linalg.lerp(player.item_dir, trans.dir, PLAYER_ITEM_ROTATION_SPEED * w.delta)
        }

        pos := player_head_pos(player, trans)
        ctx.cam.position = pos
        ctx.cam.up = UP
        ctx.cam.target = pos + trans.dir

        ecs.set(w, ctx.player, player)
}

player_head_pos :: proc(player: Player, trans: Transform) -> vec3 {
        pos := trans.pos
        pos.y += player.height
        pos += player.camera_offset

        return pos
}

right :: proc(dir: vec3) -> vec3 {
        return linalg.cross(dir, UP)
}

MOUSE_SENSITIVITY :: 0.2

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

        // just to make it more consistent
        sens := f32(MOUSE_SENSITIVITY)
        sens = sens * (SCREEN_WIDTH / f32(rl.GetScreenWidth()))

        trans.yaw = math.wrap(trans.yaw - delta.x * sens, 360)
        trans.pitch = linalg.clamp((trans.pitch - delta.y * sens), -89, 89)

        pitch := math.to_radians(trans.pitch)
        yaw := math.to_radians(trans.yaw)

        trans.dir = dir_from_yaw_and_pitch(yaw, pitch)

        ecs.set(w, e, trans)
}

dir_from_yaw_and_pitch :: proc(yaw: f32, pitch: f32) -> vec3 {
        // smart ass math, link: https://stackoverflow.com/questions/10569659/camera-pitch-yaw-to-direction-vector
        xz_len := math.cos(pitch)
        x := xz_len * math.cos(yaw)
        y := math.sin(pitch)
        z := xz_len * math.sin(-yaw)

        return {x, y, z}
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

        if mov == {} && player.mov_state != .Idle {
                player.mov_state = .Idle
                player.mov_state_started = time.tick_now()
        }
        if mov != {} && player.mov_state != .Running {
                player.mov_state = .Running
                player.mov_state_started = time.tick_now()
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
