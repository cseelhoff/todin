package game

// Java owners covered by this file:
//   - games.strategy.engine.random.PlainRandomSource

// static volatile Long fixedSeed = null;
// Phase C snapshot runs set this to 42 to pin the RNG.
plain_random_source_fixed_seed: ^i64 = nil

Plain_Random_Source :: struct {
	using i_random_source: I_Random_Source,
	lock:                  rawptr, // Java Object lock
	random:                rawptr, // org.apache.commons.math3.random.RandomGenerator (MersenneTwister)
}

