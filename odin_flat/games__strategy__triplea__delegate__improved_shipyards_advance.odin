package game

Improved_Shipyards_Advance :: struct {
	using tech_advance: Tech_Advance,
}

improved_shipyards_advance_get_property :: proc(self: ^Improved_Shipyards_Advance) -> string {
	return TECH_PROPERTY_IMPROVED_SHIPYARDS
}

improved_shipyards_advance_has_tech :: proc(self: ^Improved_Shipyards_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_shipyards(ta)
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.ImprovedShipyardsAdvance
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.ImprovedShipyardsAdvance

