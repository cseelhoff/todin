package game

Destroyer_Bombard_Tech_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: DestroyerBombardTechAdvance(GameData data)
// Mirrors `super(TECH_NAME_DESTROYER_BOMBARD, data)`. The literal
// "Destroyer Bombard" matches TechAdvance.TECH_NAME_DESTROYER_BOMBARD.
// The base is constructed via tech_advance_new (the abstract-base ctor
// port) for parity with Java's super-call; we then copy its embedded
// Named_Attachable into the subtype's `using tech_advance` slot. Note
// that the factory `make_destroyer_bombard_tech_advance` in
// tech_advance.odin already inlines this initialization for the
// predefined-technology lookup map; this proc exists as the canonical
// translation of the Java constructor for direct callers.
destroyer_bombard_tech_advance_new :: proc(data: ^Game_Data) -> ^Destroyer_Bombard_Tech_Advance {
	self := new(Destroyer_Bombard_Tech_Advance)
	base := tech_advance_new("Destroyer Bombard", data)
	self.tech_advance = base^
	free(base)
	return self
}

