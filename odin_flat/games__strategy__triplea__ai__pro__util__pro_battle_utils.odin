package game

Pro_Battle_Utils :: struct {}

// games.strategy.triplea.ai.pro.util.ProBattleUtils#estimatePower(
//     Territory t, Collection<Unit> myUnits, Collection<Unit> enemyUnits,
//     boolean attacking)
// Java:
//   final GameData data = t.getData();
//   final List<Unit> unitsThatCanFight =
//       CollectionUtils.getMatches(
//           myUnits, Matches.unitCanBeInBattle(attacking, !t.isWater(), 1, true));
//   final int myPower =
//       PowerStrengthAndRolls.build(
//               unitsThatCanFight,
//               CombatValueBuilder.mainCombatValue()
//                   .enemyUnits(enemyUnits)
//                   .friendlyUnits(unitsThatCanFight)
//                   .side(attacking ? Side.OFFENSE : Side.DEFENSE)
//                   .gameSequence(data.getSequence())
//                   .supportAttachments(data.getUnitTypeList().getSupportRules())
//                   .lhtrHeavyBombers(Properties.getLhtrHeavyBombers(data.getProperties()))
//                   .gameDiceSides(data.getDiceSides())
//                   .territoryEffects(TerritoryEffectHelper.getEffects(t))
//                   .build())
//           .calculateTotalPower();
//   return (myPower * 6.0 / data.getDiceSides());
pro_battle_utils_estimate_power :: proc(
	t:          ^Territory,
	my_units:   [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
	attacking:  bool,
) -> f64 {
	data := game_data_component_get_data(&t.named_attachable.default_named.game_data_component)

	// Filter myUnits with Matches.unitCanBeInBattle(attacking, !t.isWater(), 1, true).
	// Java's 4-arg overload delegates to the 6-arg form with
	// includeAttackersThatCanNotMove=true, doNotIncludeBombardingSeaUnits=true,
	// firingUnits=List.of().
	can_fight_pred, can_fight_ctx := matches_unit_can_be_in_battle(
		attacking,
		!territory_is_water(t),
		1,
		true,
		true,
		make([dynamic]^Unit_Type),
	)
	units_that_can_fight: [dynamic]^Unit
	for u in my_units {
		if can_fight_pred(can_fight_ctx, u) {
			append(&units_that_can_fight, u)
		}
	}

	// supportAttachments is a Set<UnitSupportAttachment> in Java; the Odin
	// builder takes [dynamic]^Unit_Support_Attachment, so flatten the map.
	support_rules_map := unit_type_list_get_support_rules(game_data_get_unit_type_list(data))
	support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in support_rules_map {
		append(&support_attachments, usa)
	}

	side: Battle_State_Side = .OFFENSE
	if !attacking {
		side = .DEFENSE
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
									units_that_can_fight,
								),
								side,
							),
							game_data_get_sequence(data),
						),
						support_attachments,
					),
					properties_get_lhtr_heavy_bombers(game_data_get_properties(data)),
				),
				int(game_data_get_dice_sides(data)),
			),
			territory_effect_helper_get_effects(t),
		),
	)
	psar := power_strength_and_rolls_build(units_that_can_fight, cv)
	my_power := power_strength_and_rolls_calculate_total_power(psar)
	return (f64(my_power) * 6.0) / f64(game_data_get_dice_sides(data))
}

