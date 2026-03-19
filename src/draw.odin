#+vet explicit-allocators
package src

import "lib:rayanim"
import "core:time"
import "core:log"
import "core:math/linalg"
import "core:container/small_array"
import rl "vendor:raylib"
import "lib:ecs"

ANIM_FRAME_TIME :: 8 * time.Millisecond

draw_equipped :: proc(w: ^ecs.World) {
        ctx := ctx(w)
        player := ecs.get(w, ctx.player, Player)
        trans := ecs.get(w, ctx.player, Transform)

        pos := player_head_pos(player, trans)

        item := small_array.get(player.items, player.current_item)

        switch item in item {
        case Gun:
                switch gun in item {
                case Double_Barrel:
                        rot := linalg.quaternion_from_forward_and_up_f32(player.item_dir, UP)
                        angle, axis := linalg.angle_axis_from_quaternion(rot)

                        log.debug("gun state", gun.state)
                        switch gun.state {
                        case .Ready:
                                anim := ctx.anims[.Double_Barrel][DOUBLE_BARRED_READY_ANIM]
                                rl.DrawModelEx(anim[0], pos, axis, linalg.to_degrees(angle), {1, 1, 1}, rl.WHITE)
                        case .Fired:
                                anim := ctx.anims[.Double_Barrel][DOUBLE_BARRED_READY_ANIM]
                                frame := rayanim.frame(anim, gun.tween.elapsed, ANIM_FRAME_TIME)
                                rl.DrawModelEx(frame, pos, axis, linalg.to_degrees(angle), {1, 1, 1}, rl.WHITE)
                        case .Reload:
                                unimplemented()
                        }
                }
        }
}

vec4_to_vec3 :: proc(v: vec4) -> (res: vec3) {
        return v.xyz
}

vec3_to_vec4 :: proc(v: vec3) -> (res: vec4) {
        res.xyz = v.xyz
        res.w = 1

        return res
}
