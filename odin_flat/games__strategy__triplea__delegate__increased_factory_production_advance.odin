package game

Increased_Factory_Production_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: IncreasedFactoryProductionAdvance(GameData data)
// Mirrors `super(TECH_NAME_INCREASED_FACTORY_PRODUCTION, data)`. The literal
// "Increased Factory Production" matches TechAdvance.TECH_NAME_INCREASED_FACTORY_PRODUCTION.
// The base is constructed via tech_advance_new (the abstract-base ctor port)
// for parity with Java's super-call; we then copy its embedded Tech_Advance
// into the subtype's `using tech_advance` slot. Note that the factory
// `make_increased_factory_production_advance` in tech_advance.odin already
// inlines this initialization for the predefined-technology lookup map; this
// proc exists as the canonical translation of the Java constructor for direct
// callers.
increased_factory_production_advance_v_has_tech :: proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
	return increased_factory_production_advance_has_tech(transmute(^Increased_Factory_Production_Advance)self, ta)
}

increased_factory_production_advance_new :: proc(data: ^Game_Data) -> ^Increased_Factory_Production_Advance {
	self := new(Increased_Factory_Production_Advance)
	base := tech_advance_new("Increased Factory Production", data)
	self.tech_advance = base^
	free(base)
	self.tech_advance.has_tech = increased_factory_production_advance_v_has_tech
	return self
}

increased_factory_production_advance_get_property :: proc(self: ^Increased_Factory_Production_Advance) -> string {
	return TECH_PROPERTY_INCREASED_FACTORY_PRODUCTION
}

increased_factory_production_advance_has_tech :: proc(self: ^Increased_Factory_Production_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_increased_factory_production(ta)
}

