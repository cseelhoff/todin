package game

Super_Subs_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: SuperSubsAdvance(GameData data) { super(TECH_NAME_SUPER_SUBS, data); }
super_subs_advance_init :: proc(self: ^Super_Subs_Advance, data: ^Game_Data) {
	self.named.base.name = "Super subs"
	self.game_data = data
	self.tech_advance.has_tech = proc(t: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return super_subs_advance_has_tech(transmute(^Super_Subs_Advance)t, ta)
	}
}

super_subs_advance_get_property :: proc(self: ^Super_Subs_Advance) -> string {
	return "superSub"
}

super_subs_advance_v_has_tech :: proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
	return super_subs_advance_has_tech(transmute(^Super_Subs_Advance)self, ta)
}

super_subs_advance_new :: proc(data: ^Game_Data) -> ^Super_Subs_Advance {
	self := new(Super_Subs_Advance)
	base := tech_advance_new("Super subs", data)
	self.tech_advance = base^
	free(base)
	self.tech_advance.has_tech = super_subs_advance_v_has_tech
	return self
}

super_subs_advance_has_tech :: proc(self: ^Super_Subs_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_super_sub(ta)
}

