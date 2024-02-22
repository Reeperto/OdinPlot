package maths

import "core:c/libc"
import "core:log"
import om "core:math"

@(private)
epsilon :: om.F32_EPSILON

inf_pos := om.inf_f32(1)
inf_neg := om.inf_f32(-1)

Bounds :: [2]f32

Interval :: struct {
	val: Bounds,
	def: [2]bool,
	con: [2]bool,
}

infsup :: proc(low, high: f32) -> Interval {
	return {val = {low, high}, def = {true, true}, con = {true, true}}
}

subset :: proc(left, right: Interval) -> bool {
	return contained(left.val, right.val)
}

contained :: proc(left, right: Bounds) -> bool {
	return left[1] <= right[1] && right[0] <= left[0]
}

float_to_interval :: proc(val: f32) -> Interval {
	return {val = {val, val}, def = {true, true}, con = {true, true}}
}

split_finite_interval :: proc(it: Interval) -> (low, high: Interval) {
	low = it
	high = it

	low.val = {it.val[0], interval_midpoint(it)}
	high.val = {low.val[1], it.val[1]}

	return
}

is_finite :: proc(it: Interval) -> bool {
	return inf_neg <= it.val[0] && it.val[1] <= inf_pos
}

interval_midpoint :: #force_inline proc(it: Interval) -> f32 {
	return (it.val[0] + it.val[1]) / 2.0
}

int_add :: proc(left, right: Interval) -> (out: Interval) {
	out.val = left.val + right.val
	out.def = {left.def[0] && right.def[0], left.def[1] && right.def[1]}
	out.con = {left.con[0] && right.con[1], true}

	return
}

int_sub :: proc(left, right: Interval) -> (out: Interval) {
	out.val = {left.val[0] - right.val[1], left.val[1] - right.val[0]}
	out.def = {left.def[0] && right.def[0], left.def[1] && right.def[1]}
	out.con = {left.con[0] && right.con[1], true}

	return
}

int_sqroot :: proc(it: Interval) -> (out: Interval) {
	if (it.val[1] < 0) {
		out.val = it.val
		out.def = {false, false}
		out.con = {false, false}
	} else if (it.val[0] >= 0) {
		out = it
		out.val = {om.sqrt(it.val[0]), om.sqrt(it.val[1])}
	} else {
		out.val = {0, om.sqrt(it.val[1])}
		out.def = {false, it.def[1]}
		out.con = {false, it.con[1]}
	}

	return
}

// TODO (Eli): Account for infinities
int_mult :: proc(int1, int2: Interval) -> (out: Interval) {
	// TODO (Eli): Maybe change this?
	out.val =  {
		om.min(
			int1.val[0] * int2.val[0],
			int1.val[0] * int2.val[1],
			int1.val[1] * int2.val[0],
			int1.val[1] * int2.val[1],
		),
		om.max(
			int1.val[0] * int2.val[0],
			int1.val[0] * int2.val[1],
			int1.val[1] * int2.val[0],
			int1.val[1] * int2.val[1],
		),
	}

	out.def = {int1.def[0] && int2.def[0], int1.def[1] && int2.def[1]}
	out.con = {int1.con[0] && int2.con[0], true}

	return
}

int_floor :: proc(it: Interval) -> (out: Interval) {
	out.val = {om.floor(it.val[0]), om.floor(it.val[1])}
	out.def = it.def

	out.con[0] = it.def[0] && (out.val[0] == out.val[1])
	out.con[1] = it.def[1]

	return
}

value_in_interval :: #force_inline proc(val: f32, it: Interval) -> bool {
	return val >= it.val[0] && val <= it.val[1]
}
