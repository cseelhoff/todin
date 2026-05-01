package game

Increased_Factory_Production_Advance :: struct {
	using tech_advance: Tech_Advance,
}

increased_factory_production_advance_get_property :: proc(self: ^Increased_Factory_Production_Advance) -> string {
	return TECH_PROPERTY_INCREASED_FACTORY_PRODUCTION
}

