#+vet explicit-allocators
package src

import "core:log"
import "core:math/linalg"
import "lib:rayanim"
import rl "vendor:raylib"
import "lib:ecs"
import "lib:mini/callback"
import "core:time"

Double_Barrel :: struct {
        loaded: int,
        ammo: int,

        state: Double_Barrel_State,
        tween: callback.Callback(^Double_Barrel),
}

Double_Barrel_State :: enum {
        Ready = 0,
        Fired,
        Reload,
}

double_barrel_animations := [Double_Barrel_State]i32 {
        .Ready = 999,
        .Fired = 0,
        .Reload = 1,
}

DOUBLE_BARRED_READY_ANIM :: 0
DOUBLE_BARRED_SHOOT_ANIM :: 1

DOUBLE_BARREL_SHOOT_DUR :: 100 * time.Millisecond
DOUBLE_BARREL_SHOOT_ANIM_DUR :: 1000 * time.Millisecond

handle_double_barrel :: proc(w: ^ecs.World, gun: ^Double_Barrel) {
        if gun.tween != {} {
                callback.update(&gun.tween, w.delta_dur, gun)
        }

        if rl.IsMouseButtonPressed(.LEFT) && gun.loaded > 0 && (gun.state == .Ready || gun.state == .Fired && gun.tween.elapsed > DOUBLE_BARREL_SHOOT_DUR) {
                gun.loaded -= 1
                gun.state = .Fired
                // TODO: check collisions, do damage and stuff

                gun.tween = callback.new(DOUBLE_BARREL_SHOOT_ANIM_DUR, proc(gun: ^Double_Barrel) {
                        gun.state = .Ready
                        gun.tween = {}
                })
        }
}

double_barrel_draw :: proc(ctx: ^Context, gun: Double_Barrel, pos: vec3, angle: f32, axis: vec3) {
        log.debug("double_barrel state", gun.state)

        switch gun.state {
        case .Ready:
                anim := ctx.anims[.Double_Barrel][DOUBLE_BARRED_READY_ANIM]
                rl.DrawModelEx(anim[0], pos, axis, linalg.to_degrees(angle), {1, 1, 1}, rl.WHITE)
        case .Fired:
                anim := ctx.anims[.Double_Barrel][DOUBLE_BARRED_SHOOT_ANIM]
                frame := anim[rayanim.frame(anim, gun.tween.elapsed, ANIM_FRAME_TIME)]
                rl.DrawModelEx(frame, pos, axis, linalg.to_degrees(angle), {1, 1, 1}, rl.WHITE)
        case .Reload:
                unimplemented()
        }
}
