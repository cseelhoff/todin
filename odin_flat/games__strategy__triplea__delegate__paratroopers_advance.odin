package game

Paratroopers_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: ParatroopersAdvance(GameData data) — public constructor that forwards
// to `super(TECH_NAME_PARATROOPERS, data)`. TECH_NAME_PARATROOPERS is the
// "Paratroopers" constant inherited from TechAdvance. Mirrors the pattern in
// `make_paratroopers_advance` in tech_advance.odin (the file-private factory
// consulted by the predefined-technology map). Allocates a concrete
// Paratroopers_Advance, initializes the embedded Named_Attachable's name and
// the Tech_Advance's GameData pointer, and wires the polymorphic `has_tech`
// dispatch field so callers using the abstract `^Tech_Advance` get the
// correct subtype behavior (Java's virtual-dispatch override of `hasTech`).
paratroopers_advance_new :: proc(data: ^Game_Data) -> ^Paratroopers_Advance {
	s := new(Paratroopers_Advance)
	s.named.base.name = "Paratroopers"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return paratroopers_advance_has_tech(transmute(^Paratroopers_Advance)self, ta)
	}
	return s
}

paratroopers_advance_get_property :: proc(self: ^Paratroopers_Advance) -> string {
	return "paratroopers"
}

paratroopers_advance_has_tech :: proc(self: ^Paratroopers_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_paratroopers(ta)
}
