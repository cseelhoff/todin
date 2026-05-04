package game

// Lombok @Builder for CombatValueBuilder.buildMainCombatValue.
// Java owner: games.strategy.triplea.delegate.power.calculator.CombatValueBuilder$MainBuilder

Combat_Value_Builder_Main_Builder :: struct {
	enemy_units:         [dynamic]^Unit,
	friendly_units:      [dynamic]^Unit,
	side:                Battle_State_Side,
	game_sequence:       ^Game_Sequence,
	support_attachments: [dynamic]^Unit_Support_Attachment,
	lhtr_heavy_bombers:  bool,
	game_dice_sides:     int,
	territory_effects:   [dynamic]^Territory_Effect,
}

combat_value_builder_main_builder_new :: proc() -> ^Combat_Value_Builder_Main_Builder {
	self := new(Combat_Value_Builder_Main_Builder)
	return self
}

combat_value_builder_main_builder_enemy_units :: proc(self: ^Combat_Value_Builder_Main_Builder, value: [dynamic]^Unit) -> ^Combat_Value_Builder_Main_Builder {
	self.enemy_units = value
	return self
}

combat_value_builder_main_builder_friendly_units :: proc(self: ^Combat_Value_Builder_Main_Builder, value: [dynamic]^Unit) -> ^Combat_Value_Builder_Main_Builder {
	self.friendly_units = value
	return self
}

combat_value_builder_main_builder_game_dice_sides :: proc(self: ^Combat_Value_Builder_Main_Builder, value: int) -> ^Combat_Value_Builder_Main_Builder {
	self.game_dice_sides = value
	return self
}

combat_value_builder_main_builder_game_sequence :: proc(self: ^Combat_Value_Builder_Main_Builder, value: ^Game_Sequence) -> ^Combat_Value_Builder_Main_Builder {
	self.game_sequence = value
	return self
}

combat_value_builder_main_builder_lhtr_heavy_bombers :: proc(self: ^Combat_Value_Builder_Main_Builder, value: bool) -> ^Combat_Value_Builder_Main_Builder {
	self.lhtr_heavy_bombers = value
	return self
}

combat_value_builder_main_builder_side :: proc(self: ^Combat_Value_Builder_Main_Builder, value: Battle_State_Side) -> ^Combat_Value_Builder_Main_Builder {
	self.side = value
	return self
}

combat_value_builder_main_builder_support_attachments :: proc(self: ^Combat_Value_Builder_Main_Builder, value: [dynamic]^Unit_Support_Attachment) -> ^Combat_Value_Builder_Main_Builder {
	self.support_attachments = value
	return self
}

combat_value_builder_main_builder_territory_effects :: proc(self: ^Combat_Value_Builder_Main_Builder, value: [dynamic]^Territory_Effect) -> ^Combat_Value_Builder_Main_Builder {
	self.territory_effects = value
	return self
}

// Adapter for the Java method reference UnitSupportAttachment::getStrength,
// matching available_supports_filter's rawptr-form predicate signature.
combat_value_builder_main_builder_pred_strength :: proc(ctx: rawptr, usa: ^Unit_Support_Attachment) -> bool {
	return unit_support_attachment_get_strength(usa)
}

// Adapter for the Java method reference UnitSupportAttachment::getRoll,
// matching available_supports_filter's rawptr-form predicate signature.
combat_value_builder_main_builder_pred_roll :: proc(ctx: rawptr, usa: ^Unit_Support_Attachment) -> bool {
	return unit_support_attachment_get_roll(usa)
}

// Java: CombatValueBuilder.MainBuilder#build()
//   Lombok @Builder-generated terminal method that delegates to
//   CombatValueBuilder.buildMainCombatValue. Computes friendly/enemy support
//   pools via SupportCalculator+AvailableSupports.getSortedSupport, filters
//   them by UnitSupportAttachment::getStrength / ::getRoll, and assembles
//   either a MainDefenseCombatValue or MainOffenseCombatValue depending on
//   side.
combat_value_builder_main_builder_build :: proc(self: ^Combat_Value_Builder_Main_Builder) -> ^Combat_Value {
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
		b := main_defense_combat_value_builder()
		b = main_defense_combat_value_main_defense_combat_value_builder_game_sequence(b, self.game_sequence)
		b = main_defense_combat_value_main_defense_combat_value_builder_game_dice_sides(b, i32(self.game_dice_sides))
		b = main_defense_combat_value_main_defense_combat_value_builder_lhtr_heavy_bombers(b, self.lhtr_heavy_bombers)
		b = main_defense_combat_value_main_defense_combat_value_builder_strength_support_from_friends(
			b,
			available_supports_filter(support_from_friends, combat_value_builder_main_builder_pred_strength, nil),
		)
		b = main_defense_combat_value_main_defense_combat_value_builder_strength_support_from_enemies(
			b,
			available_supports_filter(support_from_enemies, combat_value_builder_main_builder_pred_strength, nil),
		)
		b = main_defense_combat_value_main_defense_combat_value_builder_roll_support_from_friends(
			b,
			available_supports_filter(support_from_friends, combat_value_builder_main_builder_pred_roll, nil),
		)
		b = main_defense_combat_value_main_defense_combat_value_builder_roll_support_from_enemies(
			b,
			available_supports_filter(support_from_enemies, combat_value_builder_main_builder_pred_roll, nil),
		)
		b = main_defense_combat_value_main_defense_combat_value_builder_friend_units(b, self.friendly_units)
		b = main_defense_combat_value_main_defense_combat_value_builder_enemy_units(b, self.enemy_units)
		b = main_defense_combat_value_main_defense_combat_value_builder_territory_effects(b, self.territory_effects)
		return main_defense_combat_value_to_combat_value(
			main_defense_combat_value_main_defense_combat_value_builder_build(b),
		)
	}

	ob := main_offense_combat_value_builder()
	ob = main_offense_combat_value_main_offense_combat_value_builder_game_sequence(ob, self.game_sequence)
	ob = main_offense_combat_value_main_offense_combat_value_builder_game_dice_sides(ob, i32(self.game_dice_sides))
	ob = main_offense_combat_value_main_offense_combat_value_builder_lhtr_heavy_bombers(ob, self.lhtr_heavy_bombers)
	ob = main_offense_combat_value_main_offense_combat_value_builder_strength_support_from_friends(
		ob,
		available_supports_filter(support_from_friends, combat_value_builder_main_builder_pred_strength, nil),
	)
	ob = main_offense_combat_value_main_offense_combat_value_builder_strength_support_from_enemies(
		ob,
		available_supports_filter(support_from_enemies, combat_value_builder_main_builder_pred_strength, nil),
	)
	ob = main_offense_combat_value_main_offense_combat_value_builder_roll_support_from_friends(
		ob,
		available_supports_filter(support_from_friends, combat_value_builder_main_builder_pred_roll, nil),
	)
	ob = main_offense_combat_value_main_offense_combat_value_builder_roll_support_from_enemies(
		ob,
		available_supports_filter(support_from_enemies, combat_value_builder_main_builder_pred_roll, nil),
	)
	ob = main_offense_combat_value_main_offense_combat_value_builder_friend_units(ob, self.friendly_units)
	ob = main_offense_combat_value_main_offense_combat_value_builder_enemy_units(ob, self.enemy_units)
	ob = main_offense_combat_value_main_offense_combat_value_builder_territory_effects(ob, self.territory_effects)
	return main_offense_combat_value_to_combat_value(
		main_offense_combat_value_main_offense_combat_value_builder_build(ob),
	)
}

