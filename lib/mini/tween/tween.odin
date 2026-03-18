#+vet explicit-allocators
package tween

import "core:time"

Tween :: struct($T: typeid) {
        dur: time.Duration,
        elapsed: time.Duration,
        callback: proc(userdata: T),
        done: bool,
}

new :: proc(dur: time.Duration, callback: proc(userdata: $T)) -> Tween(T) {
        return {
                dur = dur,
                callback = callback,
        }
}

update :: proc(tw: ^Tween($T), delta: time.Duration, userdata: T) {
        if tw.done {
                return
        }

        tw.elapsed += delta
        if tw.elapsed >= tw.dur {
                tw.callback(userdata)
                tw.done = true
        }
}
