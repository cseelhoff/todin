package game

Heavy_Bomber_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: HeavyBomberAdvance(GameData data) — public constructor that forwards
// to `super(TECH_NAME_HEAVY_BOMBER, data)`. TECH_NAME_HEAVY_BOMBER is the
// "Heavy Bomber" constant inherited from TechAdvance. Mirrors the pattern in
// `make_heavy_bomber_advance` in tech_advance.odin (the file-private factory
// consulted by the predefined-technology map). Allocates a concrete
// Heavy_Bomber_Advance, initializes the embedded Named_Attachable's name and
// the Tech_Advance's GameData pointer, and wires the polymorphic `has_tech`
// dispatch field so callers using the abstract `^Tech_Advance` get the
// correct subtype behavior (Java's virtual-dispatch override of `hasTech`).
heavy_bomber_advance_new :: proc(data: ^Game_Data) -> ^Heavy_Bomber_Advance {
	s := new(Heavy_Bomber_Advance)
	s.named.base.name = "Heavy Bomber"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return heavy_bomber_advance_has_tech(transmute(^Heavy_Bomber_Advance)self, ta)
	}
	return s
}

heavy_bomber_advance_get_property :: proc(self: ^Heavy_Bomber_Advance) -> string {
	return "heavyBomber"
}

heavy_bomber_advance_has_tech :: proc(self: ^Heavy_Bomber_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_heavy_bomber(ta)
}
