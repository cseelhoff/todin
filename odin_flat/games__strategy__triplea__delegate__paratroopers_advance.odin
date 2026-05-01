package game

Paratroopers_Advance :: struct {
	using tech_advance: Tech_Advance,
}

paratroopers_advance_get_property :: proc(self: ^Paratroopers_Advance) -> string {
	return "paratroopers"
}
