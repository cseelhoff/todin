package game

// JDK shim: java.time.Instant as a plain value type.
// AI snapshot harness only needs identity/equality semantics.

Instant :: struct {
	seconds: i64,
	nanos:   i32,
}

instant_now :: proc() -> Instant {
	return Instant{seconds = 0, nanos = 0}
}

instant_of_epoch_milli :: proc(epoch_milli: i64) -> Instant {
	s := epoch_milli / 1000
	n := i32((epoch_milli % 1000) * 1_000_000)
	if n < 0 {
		s -= 1
		n += 1_000_000_000
	}
	return Instant{seconds = s, nanos = n}
}

instant_to_epoch_milli :: proc(self: Instant) -> i64 {
	return self.seconds * 1000 + i64(self.nanos / 1_000_000)
}

instant_get_epoch_second :: proc(self: Instant) -> i64 {
	return self.seconds
}

instant_equals :: proc(a, b: Instant) -> bool {
	return a.seconds == b.seconds && a.nanos == b.nanos
}

instant_is_before :: proc(a, b: Instant) -> bool {
	if a.seconds != b.seconds {
		return a.seconds < b.seconds
	}
	return a.nanos < b.nanos
}

instant_is_after :: proc(a, b: Instant) -> bool {
	return instant_is_before(b, a)
}
