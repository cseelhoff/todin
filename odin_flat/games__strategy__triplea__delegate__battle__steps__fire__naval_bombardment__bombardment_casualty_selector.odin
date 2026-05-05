package game

import "core:fmt"

Naval_Bombardment_Bombardment_Casualty_Selector :: struct {}

naval_bombardment_bombardment_casualty_selector_new :: proc() -> ^Naval_Bombardment_Bombardment_Casualty_Selector {
	self := new(Naval_Bombardment_Bombardment_Casualty_Selector)
	return self
}

// games.strategy.triplea.delegate.battle.steps.fire.NavalBombardment$BombardmentCasualtySelector#apply(IDelegateBridge,SelectCasualties)
//
// Java: build a naval-bombardment combat value (with sides swapped
// relative to the firing side because casualties are picked on the
// targets) and delegate to CasualtySelector.selectCasualties.
naval_bombardment_bombardment_casualty_selector_apply :: proc(
	self: ^Naval_Bombardment_Bombardment_Casualty_Selector,
	bridge: ^I_Delegate_Bridge,
	step: ^Select_Casualties,
) -> ^Casualty_Details {
	bs := select_casualties_get_battle_state(step)
	side := select_casualties_get_side(step)
	firing_group := select_casualties_get_firing_group(step)
	fire_round_state := select_casualties_get_fire_round_state(step)

	hit_player := battle_state_get_player(bs, battle_state_side_get_opposite(side))
	target_units := firing_group_get_target_units(firing_group)
	battle_site := battle_state_get_battle_site(bs)
	dice := fire_round_state_get_dice(fire_round_state)

	game_data := battle_state_get_game_data(bs)

	// Java: BattleState.UnitBattleFilter.ALIVE.
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	// In the casualty selector enemy/friendly are inverted relative to
	// the dice roller because the calculation is from the target's
	// (defender of the bombardment) point of view.
	enemy_units := battle_state_filter_units(bs, alive_filter, side)
	friendly_units := battle_state_filter_units(bs, alive_filter, battle_state_side_get_opposite(side))

	// Set<UnitSupportAttachment> → [dynamic]^Unit_Support_Attachment.
	support_rules_map := unit_type_list_get_support_rules(game_data_get_unit_type_list(game_data))
	support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in support_rules_map {
		append(&support_attachments, usa)
	}

	cv := combat_value_builder_naval_bombardment_builder_build(
		combat_value_builder_naval_bombardment_builder_territory_effects(
			combat_value_builder_naval_bombardment_builder_game_dice_sides(
				combat_value_builder_naval_bombardment_builder_lhtr_heavy_bombers(
					combat_value_builder_naval_bombardment_builder_support_attachments(
						combat_value_builder_naval_bombardment_builder_friendly_units(
							combat_value_builder_naval_bombardment_builder_enemy_units(
								combat_value_builder_naval_bombardment_combat_value(),
								enemy_units,
							),
							friendly_units,
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
		target_units,
		cv,
		battle_site,
		bridge,
		text,
		dice,
		battle_state_get_battle_id(bs),
		battle_status_is_headless(battle_state_get_status(bs)),
		dice_roll_get_hits(dice),
		true,
	)
}

// Stateless wrapper matching the fire_round_steps_factory_builder
// casualty_selector proc-value signature.
naval_bombardment_bombardment_casualty_selector_apply_stateless :: proc(
	bridge: ^I_Delegate_Bridge,
	step: ^Select_Casualties,
) -> ^Casualty_Details {
	return naval_bombardment_bombardment_casualty_selector_apply(nil, bridge, step)
}
