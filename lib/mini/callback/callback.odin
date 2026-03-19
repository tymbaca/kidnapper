#+vet explicit-allocators
package callback

import "core:time"

Callback :: struct($T: typeid) {
        dur: time.Duration,
        elapsed: time.Duration,
        callback: proc(userdata: T),
        done: bool,
}

new :: proc(dur: time.Duration, callback: proc(userdata: $T)) -> Callback(T) {
        return {
                dur = dur,
                callback = callback,
        }
}

update :: proc(tw: ^Callback($T), delta: time.Duration, userdata: T) {
        tw.elapsed += delta

        if tw.done {
                return
        }

        if tw.elapsed >= tw.dur {
                tw.callback(userdata)
                tw.done = true
        }
}
