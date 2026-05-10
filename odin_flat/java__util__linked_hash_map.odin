package game

// JDK shim: java.util.LinkedHashMap / java.util.LinkedHashSet.
//
// Why this exists
// ---------------
// Java's `LinkedHashMap` is a `HashMap` plus an internal doubly-linked
// list threaded through entries in **insertion order**. Iteration walks
// that list, not the hash buckets, so the order is deterministic across
// JVM runs and identical run-to-run.
//
// Odin's built-in `map[K]V` iterates in hash-bucket order. Worse, when
// the key type is a pointer (e.g. `^Territory`), the hash is over the
// pointer value itself, which changes every Odin process because the
// allocator hands out different addresses each run.
//
// The TripleA AI relies heavily on `LinkedHashMap<Territory, ...>` and
// `LinkedHashSet<Territory>` for placement, purchase, move-priority,
// and many other decisions. To keep the Odin port byte-equal with Java
// after the AI starts mutating territory state (post-purchase / place /
// move), we MUST mirror this insertion-order semantics.
//
// `Linked_Map(K, V)` here is the minimal faithful mirror:
//   - `keys`    — `[dynamic]K`, the insertion-ordered key list.
//   - `entries` — `map[K]V`, the O(1) lookup table.
//
// Iteration MUST go through `linked_map_keys(self)` (or the convenience
// macro idioms in callers — `for k in lm.keys { v := lm.entries[k] }`),
// never through `for k, v in lm.entries`.
//
// Java semantics this shim must preserve
// --------------------------------------
//   - `put(k, v)` on an EXISTING key does NOT move the key to the end —
//     it keeps the original insertion position and only updates the
//     value. `linked_map_put` matches this: append-on-first-insert only.
//   - `putAll(other)` iterates `other` in its own insertion order and
//     puts each entry into `self`, so existing keys keep their slots
//     and brand-new keys are appended in `other`'s order.
//   - `remove(k)` removes both the value and the key from the order
//     list. (Not currently used by the port; add when needed.)
//   - The default constructor is `accessOrder=false`. The accessOrder
//     LRU variant of LinkedHashMap is NOT used by TripleA, so we don't
//     implement it.
//
// `Linked_Set(K)` is the same idea backed by `Linked_Map(K, struct{})`.
//
// See `llm-instructions.md` ("Java `LinkedHashMap` / collection
// iteration order — CRITICAL") for the porting rule and the rationale
// behind why the AI care so much about this.

Linked_Map :: struct($K: typeid, $V: typeid) {
	keys:    [dynamic]K,
	entries: map[K]V,
}

linked_map_new :: proc($K: typeid, $V: typeid) -> ^Linked_Map(K, V) {
	m := new(Linked_Map(K, V))
	m.keys = make([dynamic]K)
	m.entries = make(map[K]V)
	return m
}

linked_map_init :: proc(self: ^Linked_Map($K, $V)) {
	self.keys = make([dynamic]K)
	self.entries = make(map[K]V)
}

linked_map_destroy :: proc(self: ^Linked_Map($K, $V)) {
	delete(self.keys)
	delete(self.entries)
}

// Java: V put(K, V). Updates value if key already present (keeping
// insertion slot); otherwise appends key to the order list and stores.
linked_map_put :: proc(self: ^Linked_Map($K, $V), key: K, value: V) {
	if key not_in self.entries {
		append(&self.keys, key)
	}
	self.entries[key] = value
}

// Java: V get(Object key). Returns zero V + false on miss.
linked_map_get :: proc(self: ^Linked_Map($K, $V), key: K) -> (V, bool) {
	v, ok := self.entries[key]
	return v, ok
}

linked_map_contains_key :: proc(self: ^Linked_Map($K, $V), key: K) -> bool {
	return key in self.entries
}

linked_map_size :: proc(self: ^Linked_Map($K, $V)) -> int {
	return len(self.keys)
}

linked_map_is_empty :: proc(self: ^Linked_Map($K, $V)) -> bool {
	return len(self.keys) == 0
}

// Java: void putAll(Map other). Iterates `other` in its insertion
// order; new keys are appended to `self.keys`, existing keys keep slot.
linked_map_put_all :: proc(self: ^Linked_Map($K, $V), other: ^Linked_Map(K, V)) {
	for k in other.keys {
		linked_map_put(self, k, other.entries[k])
	}
}

// -----------------------------------------------------------------
// Linked_Set — Java's LinkedHashSet, backed by Linked_Map(K, struct{}).
// -----------------------------------------------------------------

Linked_Set :: struct($K: typeid) {
	keys: [dynamic]K,
	seen: map[K]struct {},
}

linked_set_new :: proc($K: typeid) -> ^Linked_Set(K) {
	s := new(Linked_Set(K))
	s.keys = make([dynamic]K)
	s.seen = make(map[K]struct {})
	return s
}

linked_set_init :: proc(self: ^Linked_Set($K)) {
	self.keys = make([dynamic]K)
	self.seen = make(map[K]struct {})
}

linked_set_destroy :: proc(self: ^Linked_Set($K)) {
	delete(self.keys)
	delete(self.seen)
}

// Java: boolean add(K). Returns true if the set changed.
linked_set_add :: proc(self: ^Linked_Set($K), key: K) -> bool {
	if key in self.seen {
		return false
	}
	self.seen[key] = {}
	append(&self.keys, key)
	return true
}

linked_set_contains :: proc(self: ^Linked_Set($K), key: K) -> bool {
	return key in self.seen
}

linked_set_size :: proc(self: ^Linked_Set($K)) -> int {
	return len(self.keys)
}

linked_set_is_empty :: proc(self: ^Linked_Set($K)) -> bool {
	return len(self.keys) == 0
}

linked_set_add_all :: proc(self: ^Linked_Set($K), other: ^Linked_Set(K)) {
	for k in other.keys {
		linked_set_add(self, k)
	}
}
