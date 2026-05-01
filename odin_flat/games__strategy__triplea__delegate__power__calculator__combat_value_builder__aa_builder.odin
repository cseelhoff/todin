package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.CombatValueBuilder$AaBuilder

Combat_Value_Builder_Aa_Builder :: struct {
	enemy_units:         [dynamic]^Unit,
	friendly_units:      [dynamic]^Unit,
	side:                Battle_State_Side,
	support_attachments: [dynamic]^Unit_Support_Attachment,
}

combat_value_builder_aa_builder_new :: proc() -> ^Combat_Value_Builder_Aa_Builder {
	return new(Combat_Value_Builder_Aa_Builder)
}

combat_value_builder_aa_builder_enemy_units :: proc(self: ^Combat_Value_Builder_Aa_Builder, value: [dynamic]^Unit) -> ^Combat_Value_Builder_Aa_Builder {
	self.enemy_units = value
	return self
}

combat_value_builder_aa_builder_friendly_units :: proc(self: ^Combat_Value_Builder_Aa_Builder, value: [dynamic]^Unit) -> ^Combat_Value_Builder_Aa_Builder {
	self.friendly_units = value
	return self
}

combat_value_builder_aa_builder_side :: proc(self: ^Combat_Value_Builder_Aa_Builder, value: Battle_State_Side) -> ^Combat_Value_Builder_Aa_Builder {
	self.side = value
	return self
}

combat_value_builder_aa_builder_support_attachments :: proc(self: ^Combat_Value_Builder_Aa_Builder, value: [dynamic]^Unit_Support_Attachment) -> ^Combat_Value_Builder_Aa_Builder {
	self.support_attachments = value
	return self
}
