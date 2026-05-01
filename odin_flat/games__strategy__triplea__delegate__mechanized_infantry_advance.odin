package game

Mechanized_Infantry_Advance :: struct {
	using tech_advance: Tech_Advance,
}

mechanized_infantry_advance_get_property :: proc(self: ^Mechanized_Infantry_Advance) -> string {
	return "mechanizedInfantry"
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.MechanizedInfantryAdvance

