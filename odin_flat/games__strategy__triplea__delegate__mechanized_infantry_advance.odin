package game

Mechanized_Infantry_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: public MechanizedInfantryAdvance(final GameData data) {
//         super(TECH_NAME_MECHANIZED_INFANTRY, data);
//       }
// TECH_NAME_MECHANIZED_INFANTRY = "Mechanized Infantry" (see TechAdvance).
mechanized_infantry_advance_new :: proc(data: ^Game_Data) -> ^Mechanized_Infantry_Advance {
	self := new(Mechanized_Infantry_Advance)
	base := tech_advance_new("Mechanized Infantry", data)
	self.tech_advance = base^
	free(base)
	self.tech_advance.has_tech = proc(s: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return mechanized_infantry_advance_has_tech(transmute(^Mechanized_Infantry_Advance)s, ta)
	}
	return self
}

mechanized_infantry_advance_get_property :: proc(self: ^Mechanized_Infantry_Advance) -> string {
	return "mechanizedInfantry"
}

mechanized_infantry_advance_has_tech :: proc(self: ^Mechanized_Infantry_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_mechanized_infantry(ta)
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.MechanizedInfantryAdvance

