#+vet explicit-allocators
package src

import "core:log"
import "core:math/linalg"
import "core:container/small_array"
import rl "vendor:raylib"
import "lib:ecs"

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
                        model := ctx.models[.Double_Barrel]

                        rot := linalg.quaternion_from_forward_and_up_f32(player.item_dir, UP)
                        // offset = vec4_to_vec3(rot * vec3_to_vec4(offset))
                        
                        angle, axis := linalg.angle_axis_from_quaternion(rot)
                        log.debug("angle", linalg.to_degrees(angle), "axis", axis)

                        rl.DrawModelEx(model, pos, axis, linalg.to_degrees(angle), {1, 1, 1}, rl.WHITE)
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
