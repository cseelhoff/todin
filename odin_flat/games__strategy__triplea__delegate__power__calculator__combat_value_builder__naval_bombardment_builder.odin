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

// Adapter for the Java method reference UnitSupportAttachment::getStrength,
// matching available_supports_filter's rawptr-form predicate signature.
combat_value_builder_naval_bombardment_builder_pred_strength :: proc(ctx: rawptr, usa: ^Unit_Support_Attachment) -> bool {
	return unit_support_attachment_get_strength(usa)
}

// Adapter for the Java method reference UnitSupportAttachment::getRoll,
// matching available_supports_filter's rawptr-form predicate signature.
combat_value_builder_naval_bombardment_builder_pred_roll :: proc(ctx: rawptr, usa: ^Unit_Support_Attachment) -> bool {
	return unit_support_attachment_get_roll(usa)
}

// Java: CombatValueBuilder.NavalBombardmentBuilder#build()
//   Lombok @Builder-generated terminal method that delegates to
//   CombatValueBuilder.buildBombardmentCombatValue. Friendly supports are
//   computed with side = OFFENSE / allied = true; enemy supports with side =
//   DEFENSE / allied = false (these are hard-coded in the Java helper, not
//   parameterized like MainBuilder/AaBuilder). Strength/roll filters use
//   UnitSupportAttachment::getStrength and ::getRoll. Result is wrapped as a
//   CombatValue via bombardment_combat_value_to_combat_value (forward ref to
//   a higher-layer adapter).
combat_value_builder_naval_bombardment_builder_build :: proc(self: ^Combat_Value_Builder_Naval_Bombardment_Builder) -> ^Combat_Value {
	support_from_friends := available_supports_get_sorted_support(
		support_calculator_new(self.friendly_units, self.support_attachments, .OFFENSE, true),
	)
	support_from_enemies := available_supports_get_sorted_support(
		support_calculator_new(self.enemy_units, self.support_attachments, .DEFENSE, false),
	)

	b := bombardment_combat_value_builder()
	b = bombardment_combat_value_bombardment_combat_value_builder_game_dice_sides(b, self.game_dice_sides)
	b = bombardment_combat_value_bombardment_combat_value_builder_lhtr_heavy_bombers(b, self.lhtr_heavy_bombers)
	b = bombardment_combat_value_bombardment_combat_value_builder_strength_support_from_friends(
		b,
		available_supports_filter(support_from_friends, combat_value_builder_naval_bombardment_builder_pred_strength, nil),
	)
	b = bombardment_combat_value_bombardment_combat_value_builder_strength_support_from_enemies(
		b,
		available_supports_filter(support_from_enemies, combat_value_builder_naval_bombardment_builder_pred_strength, nil),
	)
	b = bombardment_combat_value_bombardment_combat_value_builder_roll_support_from_friends(
		b,
		available_supports_filter(support_from_friends, combat_value_builder_naval_bombardment_builder_pred_roll, nil),
	)
	b = bombardment_combat_value_bombardment_combat_value_builder_roll_support_from_enemies(
		b,
		available_supports_filter(support_from_enemies, combat_value_builder_naval_bombardment_builder_pred_roll, nil),
	)
	b = bombardment_combat_value_bombardment_combat_value_builder_friend_units(b, self.friendly_units)
	b = bombardment_combat_value_bombardment_combat_value_builder_enemy_units(b, self.enemy_units)
	b = bombardment_combat_value_bombardment_combat_value_builder_territory_effects(b, self.territory_effects)
	return bombardment_combat_value_to_combat_value(bombardment_combat_value_bombardment_combat_value_builder_build(b))
}
