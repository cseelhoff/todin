package game

Industrial_Technology_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: IndustrialTechnologyAdvance(GameData data)
// Mirrors `super(TECH_NAME_INDUSTRIAL_TECHNOLOGY, data)`. The literal
// "Industrial Technology" matches TechAdvance.TECH_NAME_INDUSTRIAL_TECHNOLOGY.
// The base is constructed via tech_advance_new (the abstract-base ctor
// port) for parity with Java's super-call; we then copy its embedded
// Tech_Advance into the subtype's `using tech_advance` slot. Note that
// the factory `make_industrial_technology_advance` in tech_advance.odin
// already inlines this initialization for the predefined-technology
// lookup map; this proc exists as the canonical translation of the
// Java constructor for direct callers.
industrial_technology_advance_new :: proc(data: ^Game_Data) -> ^Industrial_Technology_Advance {
	self := new(Industrial_Technology_Advance)
	base := tech_advance_new("Industrial Technology", data)
	self.tech_advance = base^
	free(base)
	return self
}

