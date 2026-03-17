#+vet explicit-allocators
package volume3d

Shape :: union {
        Sphere,
        AABB,
        Capsule,
        Ray,
}

Sphere :: struct {
        pos:    vec3,
        radius: f32,
}

AABB :: struct {
        min, max: vec3,
}

Capsule :: struct {
        bottom: vec3,
        height: f32,
        radius: f32,
}

Ray :: struct {
        start: vec3,
        dir:   vec3,
}

vec3 :: [3]f32

bounding_sphere :: proc(a, b: Shape) -> Shape {
        switch a in a {
        case Sphere:
                switch b in b {
                case Sphere:
                        return _bounding_sphere_sphere(a, b)
                case AABB:
                        return _bounding_sphere_aabb(a, b)
                case Capsule:
                        return _bounding_sphere_capsule(a, b)
                case Ray:
                        return a
                }
        case AABB:
                switch b in b {
                case Sphere:
                        return _bounding_sphere_aabb(b, a)
                case AABB:
                        return _bounding_sphere_aabb(a, b)
                case Capsule:
                        return _bounding_sphere_capsule(a, b)
                case Ray:
                        return a
                }
        case Capsule:
        case Ray:
                return b
        }
}

_bounding_sphere_sphere :: proc(a, b: Sphere) -> Sphere {
        panic("not implemented")
}

_bounding_sphere_aabb :: proc(a: Sphere, b: AABB) -> Sphere {
        panic("not implemented")
}

_bounding_aabb_sphere :: proc(a: AABB, b: Sphere) -> AABB {
        panic("not implemented")
}

_bounding_sphere_capsule :: proc(a: Sphere, b: Capsule) -> Sphere {
        panic("not implemented")
}
