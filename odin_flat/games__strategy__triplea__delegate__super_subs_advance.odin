package game

Super_Subs_Advance :: struct {
	using tech_advance: Tech_Advance,
}

super_subs_advance_get_property :: proc(self: ^Super_Subs_Advance) -> string {
	return "superSub"
}

super_subs_advance_has_tech :: proc(self: ^Super_Subs_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_super_sub(ta)
}

