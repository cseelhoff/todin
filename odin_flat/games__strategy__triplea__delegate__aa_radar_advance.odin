package game

Aa_Radar_Advance :: struct {
	using tech_advance: Tech_Advance,
}

aa_radar_advance_get_property :: proc(self: ^Aa_Radar_Advance) -> string {
	return TECH_PROPERTY_AA_RADAR
}

