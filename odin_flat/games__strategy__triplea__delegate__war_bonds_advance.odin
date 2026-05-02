package game

War_Bonds_Advance :: struct {
	using tech_advance: Tech_Advance,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.WarBondsAdvance

war_bonds_advance_get_property :: proc(self: ^War_Bonds_Advance) -> string {
	return "warBonds"
}

war_bonds_advance_has_tech :: proc(self: ^War_Bonds_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_war_bonds(ta)
}

