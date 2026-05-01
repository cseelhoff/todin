package game

Increased_Factory_Production_Advance :: struct {
	using tech_advance: Tech_Advance,
}

increased_factory_production_advance_get_property :: proc(self: ^Increased_Factory_Production_Advance) -> string {
	return TECH_PROPERTY_INCREASED_FACTORY_PRODUCTION
}

increased_factory_production_advance_has_tech :: proc(self: ^Increased_Factory_Production_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_increased_factory_production(ta)
}

