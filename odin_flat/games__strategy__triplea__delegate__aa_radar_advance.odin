package game

Aa_Radar_Advance :: struct {
	using tech_advance: Tech_Advance,
}

aa_radar_advance_get_property :: proc(self: ^Aa_Radar_Advance) -> string {
	return TECH_PROPERTY_AA_RADAR
}

aa_radar_advance_has_tech :: proc(self: ^Aa_Radar_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_aa_radar(ta)
}

