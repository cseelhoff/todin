package game

Aa_Fire_And_Casualty_Step_Aa_Dice_Roller :: struct {}

aa_fire_and_casualty_step_aa_dice_roller_new :: proc() -> ^Aa_Fire_And_Casualty_Step_Aa_Dice_Roller {
    return new(Aa_Fire_And_Casualty_Step_Aa_Dice_Roller)
}

// games.strategy.triplea.delegate.battle.steps.fire.aa.AaFireAndCasualtyStep$AaDiceRoller#apply(IDelegateBridge,RollDiceStep)
//
// Java: build the AA combat value, roll AA dice via RollDiceFactory,
// then play the AA fire sound effect (hit/miss) and return the roll.
aa_fire_and_casualty_step_aa_dice_roller_apply :: proc(
	self: ^Aa_Fire_And_Casualty_Step_Aa_Dice_Roller,
	bridge: ^I_Delegate_Bridge,
	step: ^Roll_Dice_Step,
) -> ^Dice_Roll {
	bs := roll_dice_step_get_battle_state(step)
	side := roll_dice_step_get_side(step)
	firing_group := roll_dice_step_get_firing_group(step)
	target_units := firing_group_get_target_units(firing_group)
	firing_units := firing_group_get_firing_units(firing_group)
	battle_site := battle_state_get_battle_site(bs)

	game_data := battle_state_get_game_data(bs)
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	enemy_units := battle_state_filter_units(bs, alive_filter, battle_state_side_get_opposite(side))
	friendly_units := battle_state_filter_units(bs, alive_filter, side)

	// Set<UnitSupportAttachment> → [dynamic]^Unit_Support_Attachment.
	support_aa_rules_map := unit_type_list_get_support_aa_rules(game_data_get_unit_type_list(game_data))
	support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in support_aa_rules_map {
		append(&support_attachments, usa)
	}

	cv := combat_value_builder_aa_builder_build(
		combat_value_builder_aa_builder_support_attachments(
			combat_value_builder_aa_builder_side(
				combat_value_builder_aa_builder_friendly_units(
					combat_value_builder_aa_builder_enemy_units(
						combat_value_builder_aa_combat_value(),
						enemy_units,
					),
					friendly_units,
				),
				side,
			),
			support_attachments,
		),
	)

	dice := roll_dice_factory_roll_aa_dice(target_units, firing_units, bridge, battle_site, cv)

	sound_utils_play_fire_battle_aa(
		battle_state_get_player(bs, side),
		firing_group_get_group_name(firing_group),
		dice_roll_get_hits(dice) > 0,
		bridge,
	)
	return dice
}


// Stateless wrapper matching the fire_round_steps_factory_builder
// dice_roller proc-value signature.
aa_fire_and_casualty_step_aa_dice_roller_apply_stateless :: proc(
	bridge: ^I_Delegate_Bridge,
	step: ^Roll_Dice_Step,
) -> ^Dice_Roll {
	return aa_fire_and_casualty_step_aa_dice_roller_apply(nil, bridge, step)
}
