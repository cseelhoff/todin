package game

Rockets_Advance :: struct {
	using tech_advance: Tech_Advance,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.RocketsAdvance

// Java: RocketsAdvance(GameData data) — public constructor that forwards to
// `super(TECH_NAME_ROCKETS, data)`. TECH_NAME_ROCKETS is the "Rockets Advance"
// constant inherited from TechAdvance. Mirrors the pattern in
// `make_rockets_advance` in tech_advance.odin (the file-private factory
// consulted by the predefined-technology map). Allocates a concrete
// Rockets_Advance, initializes the embedded Named_Attachable's name and the
// Tech_Advance's GameData pointer, and wires the polymorphic `has_tech`
// dispatch field so callers using the abstract `^Tech_Advance` get the
// correct subtype behavior (Java's virtual-dispatch override of `hasTech`).
rockets_advance_new :: proc(data: ^Game_Data) -> ^Rockets_Advance {
	s := new(Rockets_Advance)
	s.named.base.name = "Rockets Advance"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return rockets_advance_has_tech(transmute(^Rockets_Advance)self, ta)
	}
	return s
}

rockets_advance_get_property :: proc(self: ^Rockets_Advance) -> string {
	return TECH_PROPERTY_ROCKETS
}

rockets_advance_has_tech :: proc(self: ^Rockets_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_rocket(ta)
}

