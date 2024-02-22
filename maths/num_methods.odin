package maths

import "core:log"
import om "core:math"
import "core:slice"

// NOTE(Eli):
// For piecewise functions, examine their continuity on each sub function separately

@(private = "file")
interval_func :: proc(input: Interval) -> Interval {
	return int_mult(
		int_add(int_floor(int_sqroot(input)), float_to_interval(1.0)),
		float_to_interval(2.0),
	)
}

@(private = "file")
SearchInterval :: struct {
	it:    Interval,
	depth: u32,
}

find_discontinuities :: proc(bounds: Interval) -> ([]Bounds, []Bounds, bool) {
	max_depth :: 30

	if (!is_finite(bounds)) {
		return nil, nil, false
	}

	discontinuities: [dynamic]Bounds
	undefined: [dynamic]Bounds
	investigate: [dynamic]SearchInterval

	defer {
		delete(investigate)
	}

	append(&investigate, SearchInterval{it = bounds, depth = 0})

	for {
		if current, ok := pop_safe(&investigate); ok {
			output := interval_func(current.it)

			if output.con == {true, true} {
				continue
			}

			if output.def == {false, false} {
				is_contained := false
				for undef in &undefined {
					is_contained |= contained(current.it.val, undef)
				}
				if (!is_contained) {
					append(&undefined, current.it.val)
				}
				continue
			}

			if current.depth == max_depth {
				append(&discontinuities, current.it.val)
				continue
			}

			left, right := split_finite_interval(current.it)
			append(
				&investigate,
				SearchInterval{left, current.depth + 1},
				SearchInterval{right, current.depth + 1},
			)
		} else {
			break
		}
	}

	slice.sort_by_cmp(undefined[:], proc(left, right: Bounds) -> slice.Ordering {
		return slice.cmp(left[0], right[0])
	})

	index := 0

	for undef in &undefined {
		if undefined[index][1] >= undef[0] {
			undefined[index][1] = om.max(undefined[index][1], undef[1])
		} else {
			index += 1
			undefined[index] = undef
		}
	}

	return discontinuities[:], undefined[0:index + 1], true
}
