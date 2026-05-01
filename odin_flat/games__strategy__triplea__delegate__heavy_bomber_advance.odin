package game

Heavy_Bomber_Advance :: struct {
	using tech_advance: Tech_Advance,
}

heavy_bomber_advance_get_property :: proc(self: ^Heavy_Bomber_Advance) -> string {
	return "heavyBomber"
}
