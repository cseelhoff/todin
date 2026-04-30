package game

// JDK/Guava shim: com.google.common.collect.Multimap; minimal in-process
// implementation. The AI snapshot harness is single-threaded.
//
// Multimap maps a single key to many values. Implemented as
// `map[K][dynamic]V` with a small set of procs covering only the calls
// used by the TripleA port.

Multimap :: struct($K: typeid, $V: typeid) {
	entries: map[K][dynamic]V,
}

multimap_new :: proc($K: typeid, $V: typeid) -> ^Multimap(K, V) {
	m := new(Multimap(K, V))
	m.entries = make(map[K][dynamic]V)
	return m
}

multimap_put :: proc(self: ^Multimap($K, $V), key: K, value: V) -> bool {
	if key not_in self.entries {
		self.entries[key] = make([dynamic]V)
	}
	bucket := &self.entries[key]
	append(bucket, value)
	return true
}

multimap_get :: proc(self: ^Multimap($K, $V), key: K) -> [dynamic]V {
	if key in self.entries {
		return self.entries[key]
	}
	return make([dynamic]V)
}

multimap_contains_key :: proc(self: ^Multimap($K, $V), key: K) -> bool {
	return key in self.entries
}

multimap_size :: proc(self: ^Multimap($K, $V)) -> i32 {
	total: i32 = 0
	for _, bucket in self.entries {
		total += i32(len(bucket))
	}
	return total
}

multimap_key_set :: proc(self: ^Multimap($K, $V)) -> map[K]struct {} {
	keys: map[K]struct {}
	for k in self.entries {
		keys[k] = {}
	}
	return keys
}

multimap_remove :: proc(self: ^Multimap($K, $V), key: K, value: V) -> bool {
	if key not_in self.entries {
		return false
	}
	bucket := &self.entries[key]
	for v, i in bucket {
		if v == value {
			ordered_remove(bucket, i)
			if len(bucket) == 0 {
				delete_key(&self.entries, key)
			}
			return true
		}
	}
	return false
}

// Hash_Multimap.create() — Guava factory.
hash_multimap_create :: proc($K: typeid, $V: typeid) -> ^Multimap(K, V) {
	return multimap_new(K, V)
}

// Immutable_Multimap.copy_of(other) — Guava factory; the snapshot harness
// is single-threaded so we just return a shallow copy.
immutable_multimap_copy_of :: proc(other: ^Multimap($K, $V)) -> ^Multimap(K, V) {
	out := multimap_new(K, V)
	for k, bucket in other.entries {
		out.entries[k] = make([dynamic]V)
		dst := &out.entries[k]
		for v in bucket {
			append(dst, v)
		}
	}
	return out
}
