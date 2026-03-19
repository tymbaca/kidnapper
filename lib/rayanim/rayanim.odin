#+vet explicit-allocators
package rayanim

import "core:time"
import "core:slice"
import "core:mem"
import "core:strings"
import "base:runtime"
import "core:os"
import rl "vendor:raylib"

frame :: proc(anim: []rl.Model, elapsed: time.Duration, frame_time: time.Duration, loop := false) -> int {
        assert(len(anim) > 0)

        if len(anim) == 1 {
                return 0
        }

        frame := int(elapsed / frame_time)

        if loop {
                frame = frame % (len(anim))
        } else {
                frame = min(frame, len(anim)-1)
        }

        return frame
}

load :: proc(dir_path: string, ext: string, allocator: runtime.Allocator) -> (res: []rl.Model, err: os.Error) {
        arena: mem.Dynamic_Arena
        mem.dynamic_arena_init(&arena, allocator, allocator)
        arena_allocator := mem.dynamic_arena_allocator(&arena)
        defer free_all(arena_allocator)

        entries := os.read_all_directory_by_path(dir_path, arena_allocator) or_return
        to_open := make([dynamic]cstring, arena_allocator)

        for e, i in entries {
                if e.type == .Regular && strings.has_suffix(e.name, ext) {
                        append(&to_open, strings.clone_to_cstring(e.fullpath, arena_allocator))
                }
        }

        slice.sort(to_open[:])
        models := make([dynamic]rl.Model, allocator)

        for f in to_open {
                model := rl.LoadModel(f)
                append(&models, model)
        }

        return models[:], nil
}
