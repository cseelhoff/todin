package game

Main_Dice_Roller :: struct {
}

main_dice_roller_new :: proc() -> ^Main_Dice_Roller {
	self := new(Main_Dice_Roller)
	return self
}

// games.strategy.triplea.delegate.battle.steps.fire.MainDiceRoller#apply(IDelegateBridge,RollDiceStep)
//
// Java: build a main combat value from the firing-group context and
// delegate to RollDiceFactory.rollBattleDice for the actual dice roll.
main_dice_roller_apply :: proc(
	self: ^Main_Dice_Roller,
	bridge: ^I_Delegate_Bridge,
	step: ^Roll_Dice_Step,
) -> ^Dice_Roll {
	bs := roll_dice_step_get_battle_state(step)
	side := roll_dice_step_get_side(step)
	firing_group := roll_dice_step_get_firing_group(step)
	firing_units := firing_group_get_firing_units(firing_group)
	player := battle_state_get_player(bs, side)
	battle_site := battle_state_get_battle_site(bs)
	round := battle_status_get_round(battle_state_get_status(bs))
	annotation := dice_roll_get_annotation(firing_units, player, battle_site, round)

	game_data := battle_state_get_game_data(bs)

	// Java: BattleState.UnitBattleFilter.ACTIVE = (Alive, Casualty).
	active_filter := battle_state_unit_battle_filter_new(.Alive, .Casualty)
	enemy_units := battle_state_filter_units(bs, active_filter, battle_state_side_get_opposite(side))
	friendly_units := battle_state_filter_units(bs, active_filter, side)

	// Set<UnitSupportAttachment> → [dynamic]^Unit_Support_Attachment.
	support_rules_map := unit_type_list_get_support_rules(game_data_get_unit_type_list(game_data))
	support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in support_rules_map {
		append(&support_attachments, usa)
	}

	cv := combat_value_builder_main_builder_build(
		combat_value_builder_main_builder_territory_effects(
			combat_value_builder_main_builder_game_dice_sides(
				combat_value_builder_main_builder_lhtr_heavy_bombers(
					combat_value_builder_main_builder_support_attachments(
						combat_value_builder_main_builder_game_sequence(
							combat_value_builder_main_builder_side(
								combat_value_builder_main_builder_friendly_units(
									combat_value_builder_main_builder_enemy_units(
										combat_value_builder_main_combat_value(),
										enemy_units,
									),
									friendly_units,
								),
								side,
							),
							game_data_get_sequence(game_data),
						),
						support_attachments,
					),
					properties_get_lhtr_heavy_bombers(game_data_get_properties(game_data)),
				),
				int(game_data_get_dice_sides(game_data)),
			),
			battle_state_get_territory_effects(bs),
		),
	)

	return roll_dice_factory_roll_battle_dice(firing_units, player, bridge, annotation, cv)
}

// Stateless wrapper matching the fire_round_steps_factory_builder
// dice_roller proc-value signature `(^I_Delegate_Bridge, ^Roll_Dice_Step) -> ^Dice_Roll`.
// MainDiceRoller has no instance state so we can call the impl with nil self.
main_dice_roller_apply_stateless :: proc(
	bridge: ^I_Delegate_Bridge,
	step: ^Roll_Dice_Step,
) -> ^Dice_Roll {
	return main_dice_roller_apply(nil, bridge, step)
}
