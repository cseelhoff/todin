package game

import "core:fmt"

Select_Main_Battle_Casualties_Select :: struct {}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.fire.SelectMainBattleCasualties$Select

select_main_battle_casualties_select_new :: proc() -> ^Select_Main_Battle_Casualties_Select {
    self := new(Select_Main_Battle_Casualties_Select)
    return self
}

// games.strategy.triplea.delegate.battle.steps.fire.SelectMainBattleCasualties$Select#apply(IDelegateBridge,SelectCasualties,Collection<Unit>,int)
//
// Java: build a main combat value (with sides inverted because casualties are
// picked from the target's POV) and delegate to CasualtySelector.selectCasualties.
select_main_battle_casualties_select_apply :: proc(
	self: ^Select_Main_Battle_Casualties_Select,
	bridge: ^I_Delegate_Bridge,
	step: ^Select_Casualties,
	targets_to_pick_from: [dynamic]^Unit,
	dice_hit_override: i32,
) -> ^Casualty_Details {
	bs := select_casualties_get_battle_state(step)
	side := select_casualties_get_side(step)
	firing_group := select_casualties_get_firing_group(step)
	fire_round_state := select_casualties_get_fire_round_state(step)

	opposite_side := battle_state_side_get_opposite(side)
	hit_player := battle_state_get_player(bs, opposite_side)
	battle_site := battle_state_get_battle_site(bs)
	dice := fire_round_state_get_dice(fire_round_state)

	game_data := battle_state_get_game_data(bs)

	// Java: BattleState.UnitBattleFilter.ALIVE.
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	// Casualties are picked from the target's perspective, so enemy/friendly
	// are inverted relative to the dice roller.
	enemy_units := battle_state_filter_units(bs, alive_filter, side)
	friendly_units := battle_state_filter_units(bs, alive_filter, opposite_side)

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
								opposite_side,
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

	text := fmt.aprintf("Hits from %s, ", firing_group_get_display_name(firing_group))

	return casualty_selector_select_casualties(
		hit_player,
		targets_to_pick_from,
		cv,
		battle_site,
		bridge,
		text,
		dice,
		battle_state_get_battle_id(bs),
		battle_status_is_headless(battle_state_get_status(bs)),
		dice_hit_override,
		true,
	)
}

