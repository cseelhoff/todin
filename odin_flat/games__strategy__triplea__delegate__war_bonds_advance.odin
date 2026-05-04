package game

War_Bonds_Advance :: struct {
	using tech_advance: Tech_Advance,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.WarBondsAdvance

// Java: WarBondsAdvance(GameData data) { super(TECH_NAME_WAR_BONDS, data); }
// TECH_NAME_WAR_BONDS is the "War Bonds" constant defined on TechAdvance.
// Initializes the embedded Named_Attachable's name and the Tech_Advance's
// GameData pointer, and wires the polymorphic `has_tech` dispatch field so
// callers operating through the abstract `^Tech_Advance` get the
// WarBondsAdvance-specific override (Java's virtual `hasTech`). Mirrors the
// file-private `make_war_bonds_advance` factory in tech_advance.odin used by
// the predefined-technology map.
war_bonds_advance_init :: proc(self: ^War_Bonds_Advance, data: ^Game_Data) {
	self.named.base.name = "War Bonds"
	self.game_data = data
	self.tech_advance.has_tech = proc(t: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return war_bonds_advance_has_tech(transmute(^War_Bonds_Advance)t, ta)
	}
}

war_bonds_advance_get_property :: proc(self: ^War_Bonds_Advance) -> string {
	return "warBonds"
}

war_bonds_advance_has_tech :: proc(self: ^War_Bonds_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_war_bonds(ta)
}

