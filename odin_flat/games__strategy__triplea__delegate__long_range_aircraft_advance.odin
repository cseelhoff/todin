package game

Long_Range_Aircraft_Advance :: struct {
	using tech_advance: Tech_Advance,
}

long_range_aircraft_advance_get_property :: proc(self: ^Long_Range_Aircraft_Advance) -> string {
	return "longRangeAir"
}

long_range_aircraft_advance_has_tech :: proc(self: ^Long_Range_Aircraft_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_long_range_air(ta)
}

