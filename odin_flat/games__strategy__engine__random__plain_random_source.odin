package game

// Java owners covered by this file:
//   - games.strategy.engine.random.PlainRandomSource

// static volatile Long fixedSeed = null;
// Phase C snapshot runs set this to 42 to pin the RNG.
plain_random_source_fixed_seed: ^i64 = nil

Plain_Random_Source :: struct {
	using i_random_source: I_Random_Source,
	lock:                  rawptr, // Java Object lock
	random:                ^Mersenne_Twister, // org.apache.commons.math3.random.RandomGenerator (MersenneTwister)
}

plain_random_source_new :: proc() -> ^Plain_Random_Source {
	self := new(Plain_Random_Source)
	if plain_random_source_fixed_seed != nil {
		self.random = mersenne_twister_new_seeded(plain_random_source_fixed_seed^)
	} else {
		self.random = mersenne_twister_new()
	}
	return self
}

plain_random_source_get_random :: proc(self: ^Plain_Random_Source, max: i32, annotation: string) -> i32 {
	assert(max > 0, "max must be > 0")
	return mersenne_twister_next_int_bounded(self.random, max)
}

plain_random_source_get_random_array :: proc(self: ^Plain_Random_Source, max: i32, count: i32, annotation: string) -> [dynamic]i32 {
	assert(max > 0, "max must be > 0")
	assert(count > 0, "count must be > 0")
	numbers := make([dynamic]i32, count)
	for i in 0 ..< count {
		numbers[i] = plain_random_source_get_random(self, max, annotation)
	}
	return numbers
}


