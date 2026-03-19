#+vet explicit-allocators
package tween

import "core:math/ease"
import "core:math/linalg"
import "core:time"

Tween :: struct($T: typeid) {
	dur:            time.Duration,
	elapsed:        time.Duration,
	progress:       f32,
	initial, final: T,
	ease:           ease.Ease,
	lerp:           proc(a, b: T, x: f32) -> T,
	callback:       proc(tw: ^Tween(T)),
	done:           bool,
}

new :: proc(
	dur: time.Duration,
	inital: $T,
	final: T,
	lerp: proc(a, b: T, x: f32) -> T,
	ease := ease.Ease.Linear,
	callback: proc(tw: ^Tween(T)) = nil,
) -> Tween(T) {
	return {dur = dur, initial = inital, final = final, lerp = lerp, callback = callback}
}

update :: proc(tw: ^Tween($T), delta: time.Duration, ptr: ^T) {
	tw.elapsed += delta

	elapsed_clamped := min(tw.elapsed, tw.dur)
	tw.progress = f32(elapsed_clamped) / f32(tw.dur)

        ptr^ = tw.lerp(tw.initial, tw.final, ease.ease(tw.ease, tw.progress))

	if tw.done {
		return
	}

	if tw.elapsed >= tw.dur {
		tw.done = true
		tw.callback(tw)
	}
}

loop :: proc(tw: ^Tween($T)) {
        tw.final, tw.initial = tw.initial, tw.final
        tw.done = false
        tw.elapsed = 0
}
