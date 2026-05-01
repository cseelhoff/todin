package game

Long_Range_Aircraft_Advance :: struct {
	using tech_advance: Tech_Advance,
}

long_range_aircraft_advance_get_property :: proc(self: ^Long_Range_Aircraft_Advance) -> string {
	return "longRangeAir"
}

