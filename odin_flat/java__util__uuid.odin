package game

// JDK shim: java.util.UUID
//
// The TripleA port uses Uuid as a 16-byte value (canonical [16]u8) so it
// can be used directly as a map key. The authoritative definition lives
// in odin_flat/games__strategy__engine__data__game_data.odin so all
// callers share the same layout.
//
// Snapshot harness runs single-threaded with a fixed seed; UUID generation
// is implemented as a deterministic monotonic counter so newly-spawned
// units are reproducible across runs.

@(private="file")
_uuid_counter: u64 = 0

uuid_random_uuid :: proc() -> Uuid {
	_uuid_counter += 1
	c := _uuid_counter
	u: Uuid
	for i in 0..<8 {
		u[i] = u8((c >> uint(56 - i * 8)) & 0xff)
	}
	// Fill the lower half with a fixed pattern so generated UUIDs are
	// distinguishable from harness-loaded ones in debug output.
	for i in 8..<16 {
		u[i] = 0
	}
	// Set version (v4) and variant (RFC 4122) bits to mimic Java's UUID.randomUUID().
	u[6] = (u[6] & 0x0f) | 0x40
	u[8] = (u[8] & 0x3f) | 0x80
	return u
}
