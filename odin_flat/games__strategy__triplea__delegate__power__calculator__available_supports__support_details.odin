package game

Available_Supports_Support_Details :: struct {
	support_units: Integer_Map_Unit,
	total_support: i32,
}

// public SupportDetails(IntegerMap<Unit> supportUnits)
available_supports_support_details_new :: proc(support_units: Integer_Map_Unit) -> ^Available_Supports_Support_Details {
	self := new(Available_Supports_Support_Details)
	self.support_units = support_units
	// Preserve LinkedHashMap insertion order. If the source has keys_order
	// populated (Java-faithful path), copy it; otherwise synthesize one
	// from the entries map (lossy: pointer-hash, but matches pre-fix behavior).
	if len(support_units.keys_order) == 0 && len(support_units.entries) > 0 {
		self.support_units.keys_order = make([dynamic]^Unit)
		for k, _ in support_units.entries {
			append(&self.support_units.keys_order, k)
		}
	}
	total: i32 = 0
	for _, v in support_units.entries {
		total += v
	}
	self.total_support = total
	return self
}

// public SupportDetails(SupportDetails other)
available_supports_support_details_new_copy :: proc(other: ^Available_Supports_Support_Details) -> ^Available_Supports_Support_Details {
	self := new(Available_Supports_Support_Details)
	self.support_units.entries = make(map[^Unit]i32)
	self.support_units.keys_order = make([dynamic]^Unit)
	if len(other.support_units.keys_order) > 0 {
		for k in other.support_units.keys_order {
			self.support_units.entries[k] = other.support_units.entries[k]
			append(&self.support_units.keys_order, k)
		}
	} else {
		for k, v in other.support_units.entries {
			self.support_units.entries[k] = v
			append(&self.support_units.keys_order, k)
		}
	}
	self.total_support = other.total_support
	return self
}
