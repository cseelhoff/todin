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
	return self
}
