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

// org.triplea.java.Interruptibles#await(ThrowingRunnable)
// Single-threaded harness: invoke the runnable directly and return
// true (completed). No real interrupt handling.
interruptibles_await :: proc(runnable: ^Throwing_Runnable) -> bool {
	runnable.run()
	return true
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

// org.triplea.java.Interruptibles#await(CountDownLatch)
// Single-threaded harness: invoke the latch's await directly via the
// JDK shim and return true (completed without interruption).
interruptibles_await_latch :: proc(latch: ^Count_Down_Latch) -> bool {
	count_down_latch_await(latch)
	return true
}

// org.triplea.java.Interruptibles#join(Thread)
// Single-threaded harness: the target thread has already finished
// (threads are run inline as no-ops); return true.
interruptibles_join :: proc(thread: ^Thread) -> bool {
	thread_join(thread)
	return true
}

// org.triplea.java.Interruptibles#sleep(long)
// Snapshot harness is deterministic and time-independent; no-op.
interruptibles_sleep :: proc(millis: i64) -> bool {
	return true
}

