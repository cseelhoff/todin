package game

Rockets_Advance :: struct {
	using tech_advance: Tech_Advance,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.RocketsAdvance

rockets_advance_get_property :: proc(self: ^Rockets_Advance) -> string {
	return TECH_PROPERTY_ROCKETS
}

