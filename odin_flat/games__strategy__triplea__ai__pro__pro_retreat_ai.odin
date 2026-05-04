package game

import "core:fmt"
import "core:math"

Pro_Retreat_Ai :: struct {
	calc:     ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
}

pro_retreat_ai_new :: proc(ai: ^Abstract_Pro_Ai, allocator := context.allocator) -> ^Pro_Retreat_Ai {
	self := new(Pro_Retreat_Ai, allocator)
	self.calc = abstract_pro_ai_get_calc(ai)
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	return self
}

// Java: Optional<Territory> ProRetreatAi#retreatQuery(
//     UUID battleId, Territory battleTerritory, Collection<Territory> possibleTerritories)
// Returns ^Territory (nil = empty Optional).
pro_retreat_ai_retreat_query :: proc(
	self: ^Pro_Retreat_Ai,
	battle_id: Uuid,
	battle_territory: ^Territory,
	possible_territories: [dynamic]^Territory,
) -> ^Territory {
	// Get battle data
	data := pro_data_get_data(self.pro_data)
	player := pro_data_get_player(self.pro_data)
	delegate := game_data_get_battle_delegate(data)
	battle := battle_tracker_get_pending_battle_by_id(
		battle_delegate_get_battle_tracker(delegate),
		battle_id,
	)

	// Get units and determine if attacker
	is_attacker := player == i_battle_get_attacker(battle)
	attackers := i_battle_get_attacking_units(battle)
	defenders := i_battle_get_defending_units(battle)

	// Calculate battle results (bombardingUnits = new HashSet<>())
	bombarding := make([dynamic]^Unit)
	result := pro_odds_calculator_calculate_battle_results_no_submerge(
		self.calc,
		self.pro_data,
		battle_territory,
		attackers,
		defenders,
		bombarding,
	)

	// Determine if it has a factory
	factory_p, factory_c := pro_matches_territory_has_infra_factory_and_is_land()
	is_factory: i32 = 0
	if factory_p(factory_c, battle_territory) {
		is_factory = 1
	}

	// Determine production value and if it is a capital
	production_and_is_capital := pro_combat_move_ai_get_production_and_is_capital(battle_territory)

	// Calculate current attack value
	territory_value: f64 = 0
	air_p, air_c := matches_unit_is_air()
	none_air := true
	for u in attackers {
		if air_p(air_c, u) {
			none_air = false
			break
		}
	}
	if pro_battle_result_is_has_land_unit_remaining(result) || none_air {
		territory_value =
			pro_battle_result_get_win_percentage(result) /
			100 *
			(2.0 *
					f64(production_and_is_capital.production) *
					f64(1 + is_factory) *
					f64(1 + production_and_is_capital.is_capital))
	}
	battle_value := pro_battle_result_get_tuv_swing(result) + territory_value
	if !is_attacker {
		battle_value = -battle_value
	}

	// Decide if we should retreat
	if battle_value < 0 {
		// Retreat to capital if available otherwise the territory with highest defense strength
		retreat_territory: ^Territory = nil
		max_strength: f64 = -math.INF_F64
		my_capital := territory_attachment_get_first_owned_capital_or_first_unowned_capital(
			player,
			game_data_get_map(data),
		)
		for t in possible_territories {
			if t == my_capital {
				retreat_territory = t
				break
			}
			allied_p, allied_c := matches_is_unit_allied(player)
			my_units := territory_get_matches(t, allied_p, allied_c)
			empty_enemy := make([dynamic]^Unit)
			strength := pro_battle_utils_estimate_strength(t, my_units, empty_enemy, false)
			if strength > max_strength {
				retreat_territory = t
				max_strength = strength
			}
		}
		retreat_name := ""
		if retreat_territory != nil {
			retreat_name = territory_to_string(retreat_territory)
		}
		pro_logger_debug(
			fmt.tprintf(
				"%s retreating from territory %s to %s because AttackValue=%v, TUVSwing=%v, possibleTerritories=%d",
				default_named_get_name(&player.named_attachable.default_named),
				territory_to_string(battle_territory),
				retreat_name,
				battle_value,
				pro_battle_result_get_tuv_swing(result),
				len(possible_territories),
			),
		)
		return retreat_territory
	}
	pro_logger_debug(
		fmt.tprintf(
			"%s not retreating from territory %s with AttackValue=%v, TUVSwing=%v",
			default_named_get_name(&player.named_attachable.default_named),
			territory_to_string(battle_territory),
			battle_value,
			pro_battle_result_get_tuv_swing(result),
		),
	)
	return nil
}

