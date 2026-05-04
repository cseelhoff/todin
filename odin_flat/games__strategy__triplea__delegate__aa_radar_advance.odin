package game

Aa_Radar_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: AaRadarAdvance(GameData data) — package-private constructor that
// forwards to `super(TECH_NAME_AA_RADAR, data)`. TECH_NAME_AA_RADAR is the
// "AA Radar" constant inherited from TechAdvance. The Odin port allocates a
// concrete Aa_Radar_Advance, initializes the embedded Named_Attachable's
// name and the Tech_Advance's GameData pointer, and wires the polymorphic
// `has_tech` dispatch field to forward to `aa_radar_advance_has_tech` so
// callers using the abstract `^Tech_Advance` get the correct subtype
// behavior (Java's virtual-dispatch override of `hasTech`). Mirrors the
// pattern used by the file-private `make_aa_radar_advance` factory in
// tech_advance.odin, which is the entry consulted by
// `tech_advance_find_defined_advance_and_create_advance`.
aa_radar_advance_new :: proc(data: ^Game_Data) -> ^Aa_Radar_Advance {
	s := new(Aa_Radar_Advance)
	s.named.base.name = "AA Radar"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return aa_radar_advance_has_tech(transmute(^Aa_Radar_Advance)self, ta)
	}
	return s
}

aa_radar_advance_get_property :: proc(self: ^Aa_Radar_Advance) -> string {
	return TECH_PROPERTY_AA_RADAR
}

aa_radar_advance_has_tech :: proc(self: ^Aa_Radar_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_aa_radar(ta)
}

