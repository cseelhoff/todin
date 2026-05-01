package game

Jet_Power_Advance :: struct {
	using tech_advance: Tech_Advance,
}

jet_power_advance_get_property :: proc(self: ^Jet_Power_Advance) -> string {
	return "jetPower"
}

