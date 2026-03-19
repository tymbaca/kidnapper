#+vet explicit-allocators
package src

import "core:log"
import "lib:mini/tween"
import "core:container/small_array"
import "core:time"
import "core:math"
import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"

UP :: vec3{0, 1, 0}

Player :: struct {
        camera_offset: vec3,
        camera_offset_tween: tween.Tween(vec3),

        height: f32,
        mov_state:  Movement_State,

        items:        small_array.Small_Array(20, Inventory_Item),
        current_item: int,
        item_dir:     vec3, // for smooth animation
        item_offset:  vec3, // WARN: player rotation not applied
}

Inventory_Item :: union {
        Gun,
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

        CAMERA_BOB_HIGH :: vec3{0, 1, 0}
        CAMERA_BOB_LOW :: vec3{0, -1, 0}
        CAMERA_BOB_ZERO :: vec3{0, 0, 0}
        CAMERA_BOB_DUR :: 500*time.Millisecond

        if player.camera_offset_tween != {} {
                tween.update(&player.camera_offset_tween, w.delta_dur, &player.camera_offset)
        }

        if player.mov_state == .Running {
                if player.camera_offset_tween == {} || player.camera_offset_tween.done {
                        go_up :: proc(tw: ^tween.Tween(vec3)) {
                                tw.initial = CAMERA_BOB_LOW
                                tw.final = CAMERA_BOB_HIGH
                                tw.done = false
                                tw.elapsed = 0
                                tw.callback = go_down
                                log.debug("RUNNING tween: UP ended, callback set to DOWN")
                        }
                        go_down :: proc(tw: ^tween.Tween(vec3)) {
                                tw.initial = CAMERA_BOB_HIGH
                                tw.final = CAMERA_BOB_LOW
                                tw.done = false
                                tw.elapsed = 0
                                tw.callback = go_up
                                log.debug("RUNNING tween: DOWN ended, callback set to UP")
                        }

                        player.camera_offset_tween = tween.new_callback(CAMERA_BOB_DUR, player.camera_offset, CAMERA_BOB_HIGH, vec3_lerp, callback = go_down, ease = .Sine_In_Out)
                        log.debug("RUNNING tween created")
                }
        } else {
                if player.camera_offset != CAMERA_BOB_ZERO && player.camera_offset_tween.final != CAMERA_BOB_ZERO {
                        player.camera_offset_tween = tween.new(CAMERA_BOB_DUR, player.camera_offset, CAMERA_BOB_ZERO, vec3_lerp, ease = .Sine_In_Out)
                        log.debug("IDLE tween created")
                }
        }
        player.item_offset = player.camera_offset / 7

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
        }
        if mov != {} && player.mov_state != .Running {
                player.mov_state = .Running
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

player_item_system :: proc(w: ^ecs.World) {
        e := ctx(w).player
        trans := ecs.get(w, e, Transform)
        player := ecs.get(w, e, Player)
        movement := ecs.get(w, e, Movement)

        item := small_array.get_ptr(&player.items, player.current_item)

        switch &item in item {
        case Gun:
                switch &item in item {
                case Double_Barrel:
                        handle_double_barrel(w, &item)
                }
        }

        ecs.set(w, e, player)
}

player_current_item :: proc(player: Player) -> Inventory_Item {
        return small_array.get(player.items, player.current_item)
}
