package game

Available_Supports_Support_Details :: struct {
	support_units: Integer_Map_Unit,
	total_support: i32,
}

// public SupportDetails(IntegerMap<Unit> supportUnits)
available_supports_support_details_new :: proc(support_units: Integer_Map_Unit) -> ^Available_Supports_Support_Details {
	self := new(Available_Supports_Support_Details)
	self.support_units = support_units
	total: i32 = 0
	for _, v in support_units.entries {
		total += v
	}
	self.total_support = total
	return self
}
