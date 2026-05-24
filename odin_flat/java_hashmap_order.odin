package game

// Java HashMap iteration-order helpers.
//
// Java's HashSet/LinkedHashSet are backed by HashMap. When AI code in
// the Java port populates a `LinkedHashSet<Territory>` via
// `set.add(t)` while iterating a `HashSet<Territory>`, the resulting
// iteration order is determined by Java's HashMap bucket order over
// the source HashSet (because LinkedHashSet preserves insertion
// order, and the insertion order is the iteration order of the
// source).
//
// Odin's `map[K]V` uses an internal hash that does NOT match
// `String.hashCode`. To replicate Java's iteration order over
// territory names (which is what the AI uses for tiebreaks at e.g.
// the cruiser fallback in non-combat move), sort the territory list
// by Java HashMap bucket index BEFORE inserting into the
// LinkedHashSet-equivalent.
//
// Java algorithm (OpenJDK HashMap):
//   hash(key) = key.hashCode() ^ (key.hashCode() >>> 16)
//   bucket = (capacity - 1) & hash
//   capacity is smallest power of two such that
//     size <= capacity * 0.75; default min 16.
//
// Within a bucket, iteration order is HashMap's insertion order over
// that bucket's chain. For our small AI sets (<=20 territories at
// cap 16/32) collisions are rare; when present, the relative order of
// colliders within a bucket may differ slightly from Java's, but the
// overall order matches closely enough that downstream tiebreaks line
// up. Tracking exact insertion-order within a bucket would require
// replaying the entire HashSet construction.

// Java's String.hashCode formula: h = s[0]*31^(n-1) + ... + s[n-1].
// Returned as i32 (Java int). Wraps at 32 bits naturally.
java_string_hash :: proc(s: string) -> i32 {
	h: i32 = 0
	for i := 0; i < len(s); i += 1 {
		h = h * 31 + i32(s[i])
	}
	return h
}

// Smallest Java HashMap capacity (power of 2, min 16) that holds
// `n` entries without exceeding the default 0.75 load factor.
java_hashmap_capacity_for_size :: proc(n: int) -> int {
	if n <= 0 {
		return 16
	}
	cap := 16
	for {
		threshold := (cap * 3) / 4
		if n <= threshold {
			return cap
		}
		cap *= 2
	}
}

// Java HashMap bucket index for a String key, given a known capacity.
// Combines hashCode and supplemental hash spreading (Java 8+).
java_hashmap_bucket_for_string :: proc(s: string, capacity: int) -> int {
	h := java_string_hash(s)
	uh := u32(h)
	mixed := i32(uh ~ (uh >> 16))
	return int(mixed) & (capacity - 1)
}
