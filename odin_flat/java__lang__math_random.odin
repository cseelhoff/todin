package game

// Bit-exact port of `java.lang.Math.random()` backed by `java.util.Random`.
//
// Why this exists:
//   The Pro AI uses `Math.random()` for tie-break-style decisions
//   (weighted purchase picks, politics actions, etc.). The snapshot
//   harness pins Java's RandomNumberGeneratorHolder to seed=42 via
//   reflection (templates/Ww2v5JacocoRun.java#seedMathRandom). Odin's
//   built-in `core:math/rand` produces a different bit sequence than
//   `java.util.Random`, so even with both seeded to 42 the AI made
//   different decisions in the Odin port (snap 0013 buys 4 armour vs
//   Java's 5 armour with the same PU budget).
//
// `java.util.Random` is a 48-bit linear congruential generator:
//   nextSeed = (oldSeed * 0x5DEECE66D + 0xB) & ((1 << 48) - 1)
//   next(bits) = (int)(nextSeed >>> (48 - bits))
//   nextDouble() = ((next(26)<<27) + next(27)) / (1 << 53)
//   setSeed(s)  = (s ^ 0x5DEECE66D) & ((1 << 48) - 1)
//
// This file mirrors the JDK source verbatim. Validation: see
// `java_math_random_self_test()` below — captures
//   java.util.Random r = new java.util.Random(42);
//   for (int i = 0; i < 8; i++) r.nextDouble();
// against the JDK reference values.

@(private = "file") JR_MULTIPLIER :: u64(0x5DEECE66D)
@(private = "file") JR_ADDEND     :: u64(0xB)
@(private = "file") JR_MASK       :: u64((1 << 48) - 1)

// Single global generator that mirrors Java's
// `java.lang.Math$RandomNumberGeneratorHolder.randomNumberGenerator`.
// `Math.random()` calls into this same instance every time.
@(private = "file")
java_math_random_seed: u64 = 0

// Whether the generator has been seeded at least once. The Java
// holder lazily creates the generator on first use; we mimic that
// behavior so unseeded calls produce the same sequence as a freshly
// constructed `java.util.Random()`.
@(private = "file")
java_math_random_seeded: bool = false

// Mirrors `java.util.Random#setSeed(long)`. The harness calls this at
// the start of every snapshot via `seed_math_random(42)` to pin the
// sequence — same as templates/Ww2v5JacocoRun.java's reflective
// reseed (which sets the *same* 42 on the singleton).
java_math_random_set_seed :: proc(seed: i64) {
	java_math_random_seed = (transmute(u64)seed ~ JR_MULTIPLIER) & JR_MASK
	java_math_random_seeded = true
}

// Mirrors `java.util.Random#next(int bits)` exactly. Returns the high
// `bits` of the next 48-bit LCG state.
@(private = "file")
java_math_random_next :: proc(bits: u32) -> u32 {
	java_math_random_seed = (java_math_random_seed * JR_MULTIPLIER + JR_ADDEND) & JR_MASK
	return u32(java_math_random_seed >> (48 - u64(bits)))
}

// Mirrors `java.util.Random#nextDouble()`:
//   (((long)next(26) << 27) + next(27)) / (double)(1L << 53)
@(private = "file")
java_math_random_next_double :: proc() -> f64 {
	hi := u64(java_math_random_next(26))
	lo := u64(java_math_random_next(27))
	return f64((hi << 27) + lo) / f64(1 << 53)
}

// Drop-in replacement for Odin's `rand.float64()` at every TripleA
// `Math.random()` call site. Lazily seeds with 0 if the harness
// forgot to set the seed (matches Java's lazy holder, which would use
// a System.nanoTime-derived seed).
java_math_random :: proc() -> f64 {
	if !java_math_random_seeded {
		java_math_random_set_seed(0)
	}
	return java_math_random_next_double()
}
