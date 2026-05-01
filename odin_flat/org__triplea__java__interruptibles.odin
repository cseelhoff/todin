package game

Interruptibles :: struct {}

// Synthesized lambda from `sleep(long millis)` body
// `() -> Thread.sleep(millis)`.
// Snapshot harness is single-threaded; Thread.sleep is a no-op shim.
interruptibles_lambda_sleep_1 :: proc(millis: i64) {
}

// Synthesized lambda from `sleep(long millis, int nanos)` body
// `() -> Thread.sleep(millis, nanos)`.
// Snapshot harness is single-threaded; Thread.sleep is a no-op shim.
interruptibles_lambda_sleep_2 :: proc(millis: i64, nanos: i32) {
}

