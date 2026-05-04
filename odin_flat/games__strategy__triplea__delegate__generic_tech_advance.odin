package game

Generic_Tech_Advance :: struct {
	using tech_advance: Tech_Advance,
	advance:      ^Tech_Advance,
}

generic_tech_advance_get_advance :: proc(self: ^Generic_Tech_Advance) -> ^Tech_Advance {
	return self.advance
}

// Java: public GenericTechAdvance(String name, TechAdvance techAdvance, GameData data) {
//   super(name, data); advance = techAdvance; }
// Allocates a Generic_Tech_Advance, initializes its embedded Tech_Advance via
// the canonical tech_advance_new constructor, and stores the proxied advance.
generic_tech_advance_new :: proc(name: string, tech_advance: ^Tech_Advance, data: ^Game_Data) -> ^Generic_Tech_Advance {
	self := new(Generic_Tech_Advance)
	base := tech_advance_new(name, data)
	self.tech_advance = base^
	free(base)
	self.advance = tech_advance
	self.is_generic = true
	// Java: GenericTechAdvance forwards perform/hasTech to the wrapped
	// advance (or no-ops/checks the named generic-tech bool when no
	// wrapped advance is supplied — the latter for the null-object form).
	self.tech_advance.perform = proc(ta: ^Tech_Advance, player: ^Game_Player, bridge: ^I_Delegate_Bridge) {
		gta := transmute(^Generic_Tech_Advance)ta
		if gta.advance != nil {
			tech_advance_perform(gta.advance, player, bridge)
		}
	}
	return self
}
