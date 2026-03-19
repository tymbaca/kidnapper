#+vet explicit-allocators
package src

import rl "vendor:raylib"
import "lib:ecs"
import "lib:mini/tween"
import "core:time"

Double_Barrel :: struct {
        loaded: int,
        ammo: int,

        state: Double_Barrel_State,
        tween: tween.Tween(^Double_Barrel),
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

DOUBLE_BARREL_SHOOT_DUR :: 1000 * time.Millisecond

handle_double_barrel :: proc(w: ^ecs.World, gun: ^Double_Barrel) {
        if gun.tween != {} {
                tween.update(&gun.tween, w.delta_dur, gun)
        }

        if rl.IsMouseButtonPressed(.LEFT) && gun.loaded > 0 && gun.state == .Ready {
                gun.loaded -= 1
                gun.state = .Fired
                // TODO: check collisions, do damage and stuff

                gun.tween = tween.new(DOUBLE_BARREL_SHOOT_DUR, proc(gun: ^Double_Barrel) {
                        gun.state = .Ready
                        gun.tween = {}
                })
        }
}
