package game

Interruptibles :: struct {}

// org.triplea.java.Interruptibles#awaitResult(ThrowingSupplier)
// Single-threaded harness: no real interruption; invoke supplier
// directly and wrap result. Optional.ofNullable -> result_present
// reflects whether the supplier returned a non-nil pointer.
interruptibles_await_result :: proc(supplier: ^Throwing_Supplier) -> ^Interruptibles_Result(rawptr) {
	res := supplier.get()
	return interruptibles_result_new(rawptr, true, res != nil, res)
}

// Synthesized lambda from `await(ThrowingRunnable)` body
// `() -> { runnable.run(); return null; }`. Captures `runnable`.
interruptibles_lambda_await_0 :: proc(runnable: ^Throwing_Runnable) -> rawptr {
	runnable.run()
	return nil
}

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

