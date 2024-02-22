package tests

import "core:log"

import "../maths"

UNBOUNDED := maths.infsup(maths.inf_neg, maths.inf_pos)

interval_tests :: proc() {
	using maths

	assert(
		infsup(-1.0, 1.0) == Interval{val = {-1.0, 1.0}, def = {true, true}, con = {true, true}},
	)

	assert(int_add(infsup(-1.0, 1.0), UNBOUNDED) == UNBOUNDED)
	assert(int_sub(infsup(-1.0, 1.0), UNBOUNDED) == UNBOUNDED)

	assert(subset(infsup(-1.0, 1.0), infsup(-2.0, 2.0)))
	assert(subset(infsup(-1.0, 1.0), infsup(-1.0, 1.0)))

	log.info(int_sqroot(infsup(-1.0, 2.0)))
}
