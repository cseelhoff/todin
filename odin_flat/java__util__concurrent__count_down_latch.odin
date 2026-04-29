package game

// JDK shim: synchronous in-process implementation; the AI snapshot
// harness is single-threaded, so countDown/await reduce to plain
// counter manipulation.

Count_Down_Latch :: struct {
	count: i32,
}

count_down_latch_new :: proc(count: i32) -> ^Count_Down_Latch {
	latch := new(Count_Down_Latch)
	latch.count = count
	return latch
}

count_down_latch_count_down :: proc(self: ^Count_Down_Latch) {
	if self.count > 0 {
		self.count -= 1
	}
}

count_down_latch_await :: proc(self: ^Count_Down_Latch) {
	// Single-threaded shim: nothing else can release the latch, so
	// arriving at await with count > 0 means the caller's logic
	// would deadlock on the JVM. Treat as immediate return.
}

count_down_latch_await_timeout :: proc(self: ^Count_Down_Latch, timeout: i64, time_unit: Time_Unit) -> bool {
	return self.count == 0
}

count_down_latch_get_count :: proc(self: ^Count_Down_Latch) -> i64 {
	return i64(self.count)
}
