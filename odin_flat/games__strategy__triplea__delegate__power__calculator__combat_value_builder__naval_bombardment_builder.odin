package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.CombatValueBuilder$NavalBombardmentBuilder

Combat_Value_Builder_Naval_Bombardment_Builder :: struct {
	enemy_units:          [dynamic]^Unit,
	friendly_units:       [dynamic]^Unit,
	support_attachments:  [dynamic]^Unit_Support_Attachment,
	lhtr_heavy_bombers:   bool,
	game_dice_sides:      int,
	territory_effects:    [dynamic]^Territory_Effect,
}

combat_value_builder_naval_bombardment_builder_new :: proc() -> ^Combat_Value_Builder_Naval_Bombardment_Builder {
	self := new(Combat_Value_Builder_Naval_Bombardment_Builder)
	return self
}

combat_value_builder_naval_bombardment_builder_enemy_units :: proc(self: ^Combat_Value_Builder_Naval_Bombardment_Builder, value: [dynamic]^Unit) -> ^Combat_Value_Builder_Naval_Bombardment_Builder {
	self.enemy_units = value
	return self
}

combat_value_builder_naval_bombardment_builder_friendly_units :: proc(self: ^Combat_Value_Builder_Naval_Bombardment_Builder, value: [dynamic]^Unit) -> ^Combat_Value_Builder_Naval_Bombardment_Builder {
	self.friendly_units = value
	return self
}

combat_value_builder_naval_bombardment_builder_game_dice_sides :: proc(self: ^Combat_Value_Builder_Naval_Bombardment_Builder, value: int) -> ^Combat_Value_Builder_Naval_Bombardment_Builder {
	self.game_dice_sides = value
	return self
}

combat_value_builder_naval_bombardment_builder_lhtr_heavy_bombers :: proc(self: ^Combat_Value_Builder_Naval_Bombardment_Builder, value: bool) -> ^Combat_Value_Builder_Naval_Bombardment_Builder {
	self.lhtr_heavy_bombers = value
	return self
}

combat_value_builder_naval_bombardment_builder_support_attachments :: proc(self: ^Combat_Value_Builder_Naval_Bombardment_Builder, value: [dynamic]^Unit_Support_Attachment) -> ^Combat_Value_Builder_Naval_Bombardment_Builder {
	self.support_attachments = value
	return self
}

combat_value_builder_naval_bombardment_builder_territory_effects :: proc(self: ^Combat_Value_Builder_Naval_Bombardment_Builder, value: [dynamic]^Territory_Effect) -> ^Combat_Value_Builder_Naval_Bombardment_Builder {
	self.territory_effects = value
	return self
}
