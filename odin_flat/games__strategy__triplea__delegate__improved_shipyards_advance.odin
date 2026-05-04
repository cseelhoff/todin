package game

Improved_Shipyards_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: ImprovedShipyardsAdvance(GameData data) — forwards to
// `super(TECH_NAME_IMPROVED_SHIPYARDS, data)` (i.e. "Shipyards"). Allocates
// the concrete struct, sets the embedded Named_Attachable's name and the
// Tech_Advance's game_data pointer, and wires the polymorphic dispatch
// fields so callers using the abstract `^Tech_Advance` get the correct
// subtype behavior for `has_tech` and `get_property`.
improved_shipyards_advance_new :: proc(data: ^Game_Data) -> ^Improved_Shipyards_Advance {
	s := new(Improved_Shipyards_Advance)
	s.named.base.name = "Shipyards"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return improved_shipyards_advance_has_tech(transmute(^Improved_Shipyards_Advance)self, ta)
	}
	return s
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

