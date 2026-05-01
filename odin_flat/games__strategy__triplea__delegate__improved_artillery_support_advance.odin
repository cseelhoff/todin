package game

Improved_Artillery_Support_Advance :: struct {
	using tech_advance: Tech_Advance,
}

improved_artillery_support_advance_get_property :: proc(self: ^Improved_Artillery_Support_Advance) -> string {
	return TECH_PROPERTY_IMPROVED_ARTILLERY_SUPPORT
}

improved_artillery_support_advance_has_tech :: proc(self: ^Improved_Artillery_Support_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_improved_artillery_support(ta)
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.ImprovedArtillerySupportAdvance

