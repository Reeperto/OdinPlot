package maths

import "core:math"

generate_gl_domain :: proc(min, max: f32, n: int) -> (domain: [dynamic]f32) {
	domain = make([dynamic]f32, 2 * n)
	step := math.abs(min - max) / f32(n)

	domain[0] = min
	domain[2 * n - 1] = max

	for i in 1 ..= n - 1 {
		val := min + step * f32(i)
		domain[2 * i - 1] = val
		domain[2 * i] = val
	}

	return
}
