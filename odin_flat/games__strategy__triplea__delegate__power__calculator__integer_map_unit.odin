package game

// Integer_Map(^Unit) specialization shim.
// Java's IntegerMap is backed by LinkedHashMap; `keys_order` keeps the
// insertion-order so consumers like `available_supports_get_next_available_supporter`
// observe the same first-inserted key Java does. Writers that need the
// LinkedHashMap-faithful order MUST use `integer_map_unit_put` (or maintain
// `keys_order` themselves) rather than direct `entries[k] = v`; bare writes
// are still legal where iteration order is unobserved.
Integer_Map_Unit :: struct {
	entries:    map[^Unit]i32,
	keys_order: [dynamic]^Unit,
}

// LinkedHashMap put: append `key` to keys_order on first insertion only.
integer_map_unit_put :: proc(self: ^Integer_Map_Unit, key: ^Unit, value: i32) {
	if self.entries == nil {
		self.entries = make(map[^Unit]i32)
	}
	if _, present := self.entries[key]; !present {
		append(&self.keys_order, key)
	}
	self.entries[key] = value
}

// LinkedHashMap remove: drop key from entries and from keys_order if present.
integer_map_unit_remove :: proc(self: ^Integer_Map_Unit, key: ^Unit) {
	if _, present := self.entries[key]; !present {
		return
	}
	delete_key(&self.entries, key)
	for j := 0; j < len(self.keys_order); j += 1 {
		if self.keys_order[j] == key {
			ordered_remove(&self.keys_order, j)
			return
		}
	}
}
