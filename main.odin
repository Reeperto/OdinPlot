package main

TESTS :: #config(TEST, false)

import "tests"

main :: proc() {
	when TESTS {
		tests.run_tests()
	} else {
		run_app()
	}
}
