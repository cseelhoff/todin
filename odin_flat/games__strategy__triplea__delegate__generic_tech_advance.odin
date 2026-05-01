package game

Generic_Tech_Advance :: struct {
	using tech_advance: Tech_Advance,
	advance:      ^Tech_Advance,
}

generic_tech_advance_get_advance :: proc(self: ^Generic_Tech_Advance) -> ^Tech_Advance {
	return self.advance
}
