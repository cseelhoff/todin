package game

Paratroopers_Advance :: struct {
	using tech_advance: Tech_Advance,
}

paratroopers_advance_get_property :: proc(self: ^Paratroopers_Advance) -> string {
	return "paratroopers"
}

paratroopers_advance_has_tech :: proc(self: ^Paratroopers_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_paratroopers(ta)
}
