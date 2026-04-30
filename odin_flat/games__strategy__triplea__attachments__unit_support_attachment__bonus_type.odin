package game

Unit_Support_Attachment_Bonus_Type :: struct {
	name:  string,
	count: i32,
}
// Java owners covered by this file:
//   - games.strategy.triplea.attachments.UnitSupportAttachment$BonusType

// Java: public BonusType(@Nonnull String name, @Nonnull Integer count)
unit_support_attachment_bonus_type_new :: proc(name: string, count: ^i32) -> ^Unit_Support_Attachment_Bonus_Type {
	self := new(Unit_Support_Attachment_Bonus_Type)
	self.name = name
	self.count = count^
	return self
}

// Java: public int getCount() { return count < 0 ? Integer.MAX_VALUE : count; }
unit_support_attachment_bonus_type_get_count :: proc(self: ^Unit_Support_Attachment_Bonus_Type) -> i32 {
	if self.count < 0 {
		return max(i32)
	}
	return self.count
}

// Java: boolean isOldArtilleryRule() { return name.equals(Constants.OLD_ART_RULE_NAME); }
unit_support_attachment_bonus_type_is_old_artillery_rule :: proc(self: ^Unit_Support_Attachment_Bonus_Type) -> bool {
	return self.name == "ArtyOld"
}

