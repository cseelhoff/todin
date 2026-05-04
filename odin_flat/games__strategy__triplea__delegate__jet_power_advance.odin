package game

Jet_Power_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: JetPowerAdvance(GameData data) — public constructor that forwards
// to `super(TECH_NAME_JET_POWER, data)`. TECH_NAME_JET_POWER is the
// "Jet Power" constant inherited from TechAdvance. Mirrors the pattern in
// `make_jet_power_advance` in tech_advance.odin (the file-private factory
// consulted by the predefined-technology map). Allocates a concrete
// Jet_Power_Advance, initializes the embedded Named_Attachable's name and
// the Tech_Advance's GameData pointer, and wires the polymorphic `has_tech`
// dispatch field so callers using the abstract `^Tech_Advance` get the
// correct subtype behavior (Java's virtual-dispatch override of `hasTech`).
jet_power_advance_new :: proc(data: ^Game_Data) -> ^Jet_Power_Advance {
	s := new(Jet_Power_Advance)
	s.named.base.name = "Jet Power"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return jet_power_advance_has_tech(transmute(^Jet_Power_Advance)self, ta)
	}
	return s
}

jet_power_advance_get_property :: proc(self: ^Jet_Power_Advance) -> string {
	return "jetPower"
}

jet_power_advance_has_tech :: proc(self: ^Jet_Power_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_jet_power(ta)
}

