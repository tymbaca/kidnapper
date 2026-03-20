#+vet explicit-allocators
package src

import "lib:ecs"

GRAVITY :: vec3{0, -70, 0}

gravity_system :: proc(w: ^ecs.World) {
        for e in ecs.query(w, {Transform, Velocity}) {
                vel := ecs.get(w, e, Velocity)
                
                if p, ok := ecs.get(w, e, Player); ok {
                        if p.on_ground {
                                continue
                        }
                }
                
                vel += auto_cast GRAVITY * w.delta
                ecs.set(w, e, vel)
        }
}
