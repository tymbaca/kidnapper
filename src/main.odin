#+vet explicit-allocators
package src

import "lib:ecs"
import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

Context :: struct {
        
}

main :: proc() {
        allocator := context.allocator
        ctx: Context

        world: ecs.World
        w := &world
        
        ecs.init(w, {}, allocator)
        
        rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "kidnapper")

        cam: rl.Camera3D
        cam.up = {0, 1, 0}
        cam.fovy = 80
        cam.projection = .PERSPECTIVE
        cam.target = {0, 0, 0}
        cam.position = {0, 0, -5}

        body := rl.LoadModel("resources/body.obj")
        gun := rl.LoadModel("resources/gun.obj")

        for !rl.WindowShouldClose() {
                rl.BeginDrawing()
                rl.ClearBackground(rl.DARKGRAY)
                rl.BeginMode3D(cam)

                rl.DrawModel(body, {0,0,0}, 1, rl.WHITE)
                rl.DrawModel(gun, {0,0,0}, 1, rl.WHITE)

                rl.EndMode3D()
                rl.EndDrawing()
        }
}
