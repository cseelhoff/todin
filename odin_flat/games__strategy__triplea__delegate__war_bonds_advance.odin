package game

War_Bonds_Advance :: struct {
	using tech_advance: Tech_Advance,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.WarBondsAdvance

war_bonds_advance_get_property :: proc(self: ^War_Bonds_Advance) -> string {
	return "warBonds"
}

