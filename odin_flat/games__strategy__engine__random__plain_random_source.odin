package game

import "core:fmt"
import "core:strings"

// Java owners covered by this file:
//   - games.strategy.engine.random.PlainRandomSource

// static volatile Long fixedSeed = null;
// Phase C snapshot runs set this to 42 to pin the RNG.
plain_random_source_fixed_seed: ^i64 = nil

// ODDS_TRACE: id assigned per Plain_Random_Source so trace lines can be
// grouped per-bridge/simulation when comparing Java<->Odin streams.
@(private="file")
plain_random_source_next_id: int = 0

Plain_Random_Source :: struct {
	using i_random_source: I_Random_Source,
	lock:                  rawptr, // Java Object lock
	random:                ^Mersenne_Twister, // org.apache.commons.math3.random.RandomGenerator (MersenneTwister)
	prs_id:                int,
}

plain_random_source_new :: proc() -> ^Plain_Random_Source {
	self := new(Plain_Random_Source)
	if plain_random_source_fixed_seed != nil {
		self.random = mersenne_twister_new_seeded(plain_random_source_fixed_seed^)
	} else {
		self.random = mersenne_twister_new()
	}
	plain_random_source_next_id += 1
	self.prs_id = plain_random_source_next_id
	when #config(ODDS_TRACE, false) {
		seed_val: i64 = 0
		if plain_random_source_fixed_seed != nil { seed_val = plain_random_source_fixed_seed^ }
		fmt.printf("ODDS_PRS_NEW prs=%d seed=%d\n", self.prs_id, seed_val)
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
	when #config(ODDS_TRACE, false) {
		sb: strings.Builder
		strings.builder_init(&sb)
		defer strings.builder_destroy(&sb)
		for i in 0 ..< count {
			if i > 0 { strings.write_byte(&sb, ',') }
			fmt.sbprintf(&sb, "%d", numbers[i])
		}
		fmt.printf("ODDS_DICE prs=%d max=%d count=%d ann=%q vals=%s\n",
			self.prs_id, max, count, annotation, strings.to_string(sb))
	}
	return numbers
}


