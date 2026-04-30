package game

import "core:time"

// Java owners covered by this file:
//   - org.triplea.java.Retriable$RetriableBuilder

Retriable_Builder :: struct {
	thread_sleeper: proc(d: time.Duration),
	max_attempts:   int,
	fixed_back_off: time.Duration,
	task_runner:    proc() -> (rawptr, bool),
}

