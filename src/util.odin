#+vet explicit-allocators
package src

import "core:math/linalg"

vec3_lerp :: proc(a, b: vec3, x: f32) -> vec3 {
        return linalg.lerp(a, b, x)
}
