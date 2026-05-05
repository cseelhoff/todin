package game

import "core:fmt"

Aa_Fire_And_Casualty_Step_Select_Aa_Casualties :: struct {}

aa_fire_and_casualty_step_select_aa_casualties_new :: proc() -> ^Aa_Fire_And_Casualty_Step_Select_Aa_Casualties {
    return new(Aa_Fire_And_Casualty_Step_Select_Aa_Casualties)
}

// games.strategy.triplea.delegate.battle.steps.fire.aa.AaFireAndCasualtyStep$SelectAaCasualties#apply(IDelegateBridge,SelectCasualties)
//
// Java: build a main combat value (sides inverted — casualties are picked from
// the target's POV) and an AA combat value, then delegate to
// AaCasualtySelector.getAaCasualties.
aa_fire_and_casualty_step_select_aa_casualties_apply :: proc(
	self: ^Aa_Fire_And_Casualty_Step_Select_Aa_Casualties,
	bridge: ^I_Delegate_Bridge,
	step: ^Select_Casualties,
) -> ^Casualty_Details {
	bs := select_casualties_get_battle_state(step)
	side := select_casualties_get_side(step)
	opposite_side := battle_state_side_get_opposite(side)
	firing_group := select_casualties_get_firing_group(step)
	fire_round_state := select_casualties_get_fire_round_state(step)

	target_units := firing_group_get_target_units(firing_group)
	firing_units := firing_group_get_firing_units(firing_group)

	game_data := battle_state_get_game_data(bs)
	alive_filter := battle_state_unit_battle_filter_new(.Alive)

	// Main combat value: enemy=side, friendly=opposite, side=opposite (target POV).
	main_enemy_units := battle_state_filter_units(bs, alive_filter, side)
	main_friendly_units := battle_state_filter_units(bs, alive_filter, opposite_side)

	main_support_rules_map := unit_type_list_get_support_rules(game_data_get_unit_type_list(game_data))
	main_support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in main_support_rules_map {
		append(&main_support_attachments, usa)
	}

	main_cv := combat_value_builder_main_builder_build(
		combat_value_builder_main_builder_territory_effects(
			combat_value_builder_main_builder_game_dice_sides(
				combat_value_builder_main_builder_lhtr_heavy_bombers(
					combat_value_builder_main_builder_support_attachments(
						combat_value_builder_main_builder_game_sequence(
							combat_value_builder_main_builder_side(
								combat_value_builder_main_builder_friendly_units(
									combat_value_builder_main_builder_enemy_units(
										combat_value_builder_main_combat_value(),
										main_enemy_units,
									),
									main_friendly_units,
								),
								opposite_side,
							),
							game_data_get_sequence(game_data),
						),
						main_support_attachments,
					),
					properties_get_lhtr_heavy_bombers(game_data_get_properties(game_data)),
				),
				int(game_data_get_dice_sides(game_data)),
			),
			battle_state_get_territory_effects(bs),
		),
	)

	// AA combat value: enemy=opposite, friendly=side, side=side, supportAaRules.
	aa_enemy_units := battle_state_filter_units(bs, alive_filter, opposite_side)
	aa_friendly_units := battle_state_filter_units(bs, alive_filter, side)

	aa_support_rules_map := unit_type_list_get_support_aa_rules(game_data_get_unit_type_list(game_data))
	aa_support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in aa_support_rules_map {
		append(&aa_support_attachments, usa)
	}

	aa_cv := combat_value_builder_aa_builder_build(
		combat_value_builder_aa_builder_support_attachments(
			combat_value_builder_aa_builder_side(
				combat_value_builder_aa_builder_friendly_units(
					combat_value_builder_aa_builder_enemy_units(
						combat_value_builder_aa_combat_value(),
						aa_enemy_units,
					),
					aa_friendly_units,
				),
				side,
			),
			aa_support_attachments,
		),
	)

	text := fmt.aprintf("Hits from %s, ", firing_group_get_display_name(firing_group))
	dice := fire_round_state_get_dice(fire_round_state)

	return aa_casualty_selector_get_aa_casualties(
		target_units,
		firing_units,
		main_cv,
		aa_cv,
		text,
		dice,
		bridge,
		battle_state_get_player(bs, opposite_side),
		battle_state_get_battle_id(bs),
		battle_state_get_battle_site(bs),
	)
}
