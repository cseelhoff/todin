package game

Improved_Artillery_Support_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: ImprovedArtillerySupportAdvance(GameData data)
//   super(TECH_NAME_IMPROVED_ARTILLERY_SUPPORT, data)
// which threads through TechAdvance(String, GameData) → NamedAttachable(name, data).
// TechAdvance.TECH_NAME_IMPROVED_ARTILLERY_SUPPORT is the literal "Improved Artillery Support".
improved_artillery_support_advance_new :: proc(data: ^Game_Data) -> ^Improved_Artillery_Support_Advance {
	self := new(Improved_Artillery_Support_Advance)
	base := named_attachable_new("Improved Artillery Support", data)
	self.named_attachable = base^
	free(base)
	self.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return improved_artillery_support_advance_has_tech(transmute(^Improved_Artillery_Support_Advance)self, ta)
	}
	return self
}

improved_artillery_support_advance_get_property :: proc(self: ^Improved_Artillery_Support_Advance) -> string {
	return TECH_PROPERTY_IMPROVED_ARTILLERY_SUPPORT
}

improved_artillery_support_advance_has_tech :: proc(self: ^Improved_Artillery_Support_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_improved_artillery_support(ta)
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.ImprovedArtillerySupportAdvance

