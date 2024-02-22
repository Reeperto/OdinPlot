package tests

import "core:log"
import "core:testing"


run_tests :: proc() {
	context.logger = log.create_console_logger()
    log.info("Running tests")

    interval_tests()
}
