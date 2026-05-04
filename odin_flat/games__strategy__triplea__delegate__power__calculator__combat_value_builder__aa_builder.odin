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

// Adapter for the Java method reference UnitSupportAttachment::getAaStrength,
// matching available_supports_filter's rawptr-form predicate signature.
combat_value_builder_aa_builder_pred_aa_strength :: proc(ctx: rawptr, usa: ^Unit_Support_Attachment) -> bool {
	return unit_support_attachment_get_aa_strength(usa)
}

// Adapter for the Java method reference UnitSupportAttachment::getAaRoll,
// matching available_supports_filter's rawptr-form predicate signature.
combat_value_builder_aa_builder_pred_aa_roll :: proc(ctx: rawptr, usa: ^Unit_Support_Attachment) -> bool {
	return unit_support_attachment_get_aa_roll(usa)
}

// Java: CombatValueBuilder.AaBuilder#build()
//   Lombok @Builder-generated terminal method that delegates to
//   CombatValueBuilder.buildAaCombatValue. Computes friendly/enemy support
//   pools via SupportCalculator+AvailableSupports.getSortedSupport, filters
//   them by UnitSupportAttachment::getAaStrength / ::getAaRoll, and assembles
//   either an AaDefenseCombatValue or AaOffenseCombatValue depending on side.
combat_value_builder_aa_builder_build :: proc(self: ^Combat_Value_Builder_Aa_Builder) -> ^Combat_Value {
	support_from_friends := available_supports_get_sorted_support(
		support_calculator_new(self.friendly_units, self.support_attachments, self.side, true),
	)
	support_from_enemies := available_supports_get_sorted_support(
		support_calculator_new(
			self.enemy_units,
			self.support_attachments,
			battle_state_side_get_opposite(self.side),
			false,
		),
	)

	if self.side == .DEFENSE {
		b := aa_defense_combat_value_builder()
		b = aa_defense_combat_value_builder_strength_support_from_friends(
			b,
			available_supports_filter(support_from_friends, combat_value_builder_aa_builder_pred_aa_strength, nil),
		)
		b = aa_defense_combat_value_builder_strength_support_from_enemies(
			b,
			available_supports_filter(support_from_enemies, combat_value_builder_aa_builder_pred_aa_strength, nil),
		)
		b = aa_defense_combat_value_builder_roll_support_from_friends(
			b,
			available_supports_filter(support_from_friends, combat_value_builder_aa_builder_pred_aa_roll, nil),
		)
		b = aa_defense_combat_value_builder_roll_support_from_enemies(
			b,
			available_supports_filter(support_from_enemies, combat_value_builder_aa_builder_pred_aa_roll, nil),
		)
		b = aa_defense_combat_value_builder_friend_units(b, self.friendly_units)
		b = aa_defense_combat_value_builder_enemy_units(b, self.enemy_units)
		return aa_defense_combat_value_to_combat_value(aa_defense_combat_value_builder_build(b))
	}

	ob := aa_offense_combat_value_builder()
	ob = aa_offense_combat_value_aa_offense_combat_value_builder_strength_support_from_friends(
		ob,
		available_supports_filter(support_from_friends, combat_value_builder_aa_builder_pred_aa_strength, nil),
	)
	ob = aa_offense_combat_value_aa_offense_combat_value_builder_strength_support_from_enemies(
		ob,
		available_supports_filter(support_from_enemies, combat_value_builder_aa_builder_pred_aa_strength, nil),
	)
	ob = aa_offense_combat_value_aa_offense_combat_value_builder_roll_support_from_friends(
		ob,
		available_supports_filter(support_from_friends, combat_value_builder_aa_builder_pred_aa_roll, nil),
	)
	ob = aa_offense_combat_value_aa_offense_combat_value_builder_roll_support_from_enemies(
		ob,
		available_supports_filter(support_from_enemies, combat_value_builder_aa_builder_pred_aa_roll, nil),
	)
	ob = aa_offense_combat_value_aa_offense_combat_value_builder_friend_units(ob, self.friendly_units)
	ob = aa_offense_combat_value_aa_offense_combat_value_builder_enemy_units(ob, self.enemy_units)
	return aa_offense_combat_value_to_combat_value(aa_offense_combat_value_aa_offense_combat_value_builder_build(ob))
}
