package game

Casualty_Selector :: struct {}

casualty_selector_clear_ool_cache :: proc() {
	casualty_order_of_losses_clear_ool_cache()
}

casualty_selector_lambda_select_casualties_0 :: proc(u: ^Unit) -> bool {
	return unit_attachment_get_is_marine(unit_get_unit_attachment(u)) != 0 &&
		unit_get_was_amphibious(u)
}

casualty_selector_all_targets_one_type_one_hit_point :: proc(
	targets: [dynamic]^Unit,
	dependents: map[^Unit][dynamic]^Unit,
	properties: ^Game_Properties,
) -> bool {
	separate_by_retreat_possibility := properties_get_partial_amphibious_retreat(properties)
	builder := unit_separator_separator_categories_separator_categories_builder_new()
	unit_separator_separator_categories_separator_categories_builder_retreat_possibility(
		builder,
		separate_by_retreat_possibility,
	)
	unit_separator_separator_categories_separator_categories_builder_dependents(builder, dependents)
	separator_categories := unit_separator_separator_categories_separator_categories_builder_build(
		builder,
	)
	categorized := unit_separator_categorize(targets, separator_categories)
	if len(categorized) == 1 {
		unit_category := categorized[0]
		return(
			unit_category_get_hit_points(unit_category) -
				unit_category_get_damaged(unit_category) <=
			1 \
		)
	}
	return false
}

casualty_selector_get_casualty_order_of_loss :: proc(
	targets_to_pick_from: [dynamic]^Unit,
	player: ^Game_Player,
	combat_value: ^Combat_Value,
	battlesite: ^Territory,
	costs: ^Integer_Map_Unit_Type,
	data: ^Game_State,
) -> [dynamic]^Unit {
	builder := casualty_order_of_losses_parameters_parameters_builder_new()
	casualty_order_of_losses_parameters_parameters_builder_targets_to_pick_from(
		builder,
		targets_to_pick_from,
	)
	casualty_order_of_losses_parameters_parameters_builder_player(builder, player)
	casualty_order_of_losses_parameters_parameters_builder_combat_value(builder, combat_value)
	casualty_order_of_losses_parameters_parameters_builder_battlesite(builder, battlesite)
	casualty_order_of_losses_parameters_parameters_builder_costs(builder, costs)
	casualty_order_of_losses_parameters_parameters_builder_data(builder, data)
	parameters := casualty_order_of_losses__parameters__parameters_builder_build(builder)
	return casualty_order_of_losses_sort_units_for_casualties_with_support(parameters)
}

casualty_selector_get_default_casualties :: proc(
	targets_to_pick_from: [dynamic]^Unit,
	hits: i32,
	player: ^Game_Player,
	combat_value: ^Combat_Value,
	battlesite: ^Territory,
	costs: ^Integer_Map_Unit_Type,
	data: ^Game_State,
	allow_multiple_hits_per_unit: bool,
) -> ^Tuple(^Casualty_List, [dynamic]^Unit) {
	default_casualty_selection := casualty_list_new()
	sorted := casualty_selector_get_casualty_order_of_loss(
		targets_to_pick_from,
		player,
		combat_value,
		battlesite,
		costs,
		data,
	)
	if allow_multiple_hits_per_unit {
		for unit in sorted {
			num_selected_casualties := i32(casualty_list_size(default_casualty_selection))
			if num_selected_casualties >= hits {
				return tuple_new(
					^Casualty_List,
					[dynamic]^Unit,
					default_casualty_selection,
					sorted,
				)
			}
			ua := unit_get_unit_attachment(unit)
			extra_hit_points := hits - num_selected_casualties
			capacity := unit_attachment_get_hit_points(ua) - (1 + unit_get_hits(unit))
			if capacity < extra_hit_points {
				extra_hit_points = capacity
			}
			for i: i32 = 0; i < extra_hit_points; i += 1 {
				casualty_list_add_to_damaged_one(default_casualty_selection, unit)
			}
		}
	}
	for unit in sorted {
		if i32(casualty_list_size(default_casualty_selection)) >= hits {
			return tuple_new(
				^Casualty_List,
				[dynamic]^Unit,
				default_casualty_selection,
				sorted,
			)
		}
		casualty_list_add_to_killed(default_casualty_selection, unit)
	}
	return tuple_new(^Casualty_List, [dynamic]^Unit, default_casualty_selection, sorted)
}

// `unitIsAir()` matcher specialized to the bare `proc(^Unit) -> bool` form
// expected by `casualty_details_ensure_units_are_*_first`.
casualty_selector_lambda_select_casualties_is_air :: proc(u: ^Unit) -> bool {
	return unit_attachment_is_air(unit_get_unit_attachment(u))
}

// `Comparator.comparing(Unit::getMovementLeft)` — less-than on movement_left.
casualty_selector_lambda_select_casualties_movement_asc :: proc(a: ^Unit, b: ^Unit) -> bool {
	return unit_get_movement_left(a) < unit_get_movement_left(b)
}

// `Comparator.comparing(Unit::getMovementLeft).reversed()`.
casualty_selector_lambda_select_casualties_movement_desc :: proc(a: ^Unit, b: ^Unit) -> bool {
	return unit_get_movement_left(a) > unit_get_movement_left(b)
}

// games.strategy.triplea.delegate.battle.casualty.CasualtySelector#selectCasualties
casualty_selector_select_casualties :: proc(
	player: ^Game_Player,
	targets_to_pick_from: [dynamic]^Unit,
	combat_value: ^Combat_Value,
	battle_site: ^Territory,
	bridge: ^I_Delegate_Bridge,
	text: string,
	dice: ^Dice_Roll,
	battle_id: Uuid,
	head_less: bool,
	extra_hits: i32,
	allow_multiple_hits_per_unit: bool,
) -> ^Casualty_Details {
	if len(targets_to_pick_from) == 0 {
		return casualty_details_new()
	}
	data := i_delegate_bridge_get_data(bridge)

	triplea_player: ^Player
	if game_player_is_null(player) {
		triplea_player = cast(^Player)weak_ai_new(player.name)
	} else {
		triplea_player = i_delegate_bridge_get_remote_player(bridge, player)
	}

	dependents: map[^Unit][dynamic]^Unit
	if head_less {
		dependents = make(map[^Unit][dynamic]^Unit)
	} else {
		dependents = casualty_util_get_dependents(targets_to_pick_from)
	}

	hits_remaining: i32
	if properties_get_transport_casualties_restricted(game_data_get_properties(data)) {
		hits_remaining = extra_hits
	} else {
		hits_remaining = dice_roll_get_hits(dice)
	}

	if edit_delegate_get_edit_mode(game_data_get_properties(data)) {
		empty_amphib := make([dynamic]^Unit)
		return player_select_casualties(
			triplea_player,
			targets_to_pick_from,
			dependents,
			hits_remaining,
			text,
			dice,
			player,
			combat_value_get_friend_units(combat_value),
			combat_value_get_enemy_units(combat_value),
			false,
			empty_amphib,
			casualty_details_new(),
			battle_id,
			battle_site,
			allow_multiple_hits_per_unit,
		)
	}

	if dice_roll_get_hits(dice) == 0 {
		return casualty_details_new()
	}

	costs_map := i_delegate_bridge_get_costs_for_tuv(bridge, player)
	costs := new(Integer_Map_Unit_Type)
	costs.entries = costs_map

	default_casualties_and_sorted_targets := casualty_selector_get_default_casualties(
		targets_to_pick_from,
		hits_remaining,
		player,
		combat_value,
		battle_site,
		costs,
		&data.game_state,
		allow_multiple_hits_per_unit,
	)
	default_casualties := tuple_get_first(default_casualties_and_sorted_targets)
	sorted_targets_to_pick_from := tuple_get_second(default_casualties_and_sorted_targets)
	if len(sorted_targets_to_pick_from) != len(targets_to_pick_from) {
		panic(
			"sortedTargetsToPickFrom must have the same size as targetsToPickFrom list",
		)
	}

	total_hitpoints: i32
	if allow_multiple_hits_per_unit {
		total_hitpoints = casualty_util_get_total_hitpoints_left(sorted_targets_to_pick_from)
	} else {
		total_hitpoints = i32(len(sorted_targets_to_pick_from))
	}

	auto_choose_casualties :=
		hits_remaining >= total_hitpoints ||
		len(sorted_targets_to_pick_from) == 1 ||
		casualty_selector_all_targets_one_type_one_hit_point(
			sorted_targets_to_pick_from,
			dependents,
			game_data_get_properties(data),
		)

	casualty_details: ^Casualty_Details
	if auto_choose_casualties {
		casualty_details = casualty_details_new_from_list_auto_calculated(
			default_casualties,
			true,
		)
	} else {
		if i32(casualty_list_size(default_casualties)) != hits_remaining {
			panic(
				"Select Casualties showing different numbers for number of hits to take vs total size of default casualty selections",
			)
		}
		empty_amphib := make([dynamic]^Unit)
		casualty_details = player_select_casualties(
			triplea_player,
			sorted_targets_to_pick_from,
			dependents,
			hits_remaining,
			text,
			dice,
			player,
			combat_value_get_friend_units(combat_value),
			combat_value_get_enemy_units(combat_value),
			false,
			empty_amphib,
			default_casualties,
			battle_id,
			battle_site,
			allow_multiple_hits_per_unit,
		)
	}

	if !properties_get_partial_amphibious_retreat(game_data_get_properties(data)) {
		units_with_marine_bonus_and_was_amphibious_killed := false
		for u in casualty_details.killed {
			if casualty_selector_lambda_select_casualties_0(u) {
				units_with_marine_bonus_and_was_amphibious_killed = true
				break
			}
		}
		if units_with_marine_bonus_and_was_amphibious_killed {
			casualty_details_ensure_units_with_positive_marine_bonus_are_killed_last(
				casualty_details,
				sorted_targets_to_pick_from[:],
			)
		}
	}

	casualty_details_ensure_units_are_killed_first(
		casualty_details,
		sorted_targets_to_pick_from[:],
		casualty_selector_lambda_select_casualties_is_air,
		casualty_selector_lambda_select_casualties_movement_asc,
	)

	casualty_details_ensure_units_are_damaged_first(
		casualty_details,
		sorted_targets_to_pick_from[:],
		casualty_selector_lambda_select_casualties_is_air,
		casualty_selector_lambda_select_casualties_movement_desc,
	)

	numhits := i32(len(casualty_details.killed))
	if !allow_multiple_hits_per_unit {
		clear(&casualty_details.damaged)
	} else {
		// snapshot killed list — we mutate damaged inside the loop.
		killed_snapshot := make([dynamic]^Unit, 0, len(casualty_details.killed))
		defer delete(killed_snapshot)
		for u in casualty_details.killed do append(&killed_snapshot, u)
		for unit in killed_snapshot {
			ua := unit_get_unit_attachment(unit)
			damage_to_unit: i32 = 0
			for d in casualty_details.damaged {
				if d == unit {
					damage_to_unit += 1
				}
			}
			allowed := unit_attachment_get_hit_points(ua) - (1 + unit_get_hits(unit))
			v := damage_to_unit
			if allowed < v {
				v = allowed
			}
			if v < 0 {
				v = 0
			}
			numhits += v
			// damaged.removeIf(unit::equals)
			write_idx := 0
			for i := 0; i < len(casualty_details.damaged); i += 1 {
				d := casualty_details.damaged[i]
				if d != unit {
					casualty_details.damaged[write_idx] = d
					write_idx += 1
				}
			}
			resize(&casualty_details.damaged, write_idx)
		}
	}

	expected_hits: i32 = hits_remaining
	if total_hitpoints < expected_hits {
		expected_hits = total_hitpoints
	}
	if numhits + i32(len(casualty_details.damaged)) != expected_hits {
		player_report_error(triplea_player, "Wrong number of casualties selected")
		return casualty_selector_select_casualties(
			player,
			sorted_targets_to_pick_from,
			combat_value,
			battle_site,
			bridge,
			text,
			dice,
			battle_id,
			head_less,
			extra_hits,
			allow_multiple_hits_per_unit,
		)
	}

	all_killed_in := true
	for n in casualty_details.killed {
		found := false
		for h in sorted_targets_to_pick_from {
			if h == n {
				found = true
				break
			}
		}
		if !found {
			all_killed_in = false
			break
		}
	}
	all_damaged_in := true
	for n in casualty_details.damaged {
		found := false
		for h in sorted_targets_to_pick_from {
			if h == n {
				found = true
				break
			}
		}
		if !found {
			all_damaged_in = false
			break
		}
	}
	if !all_killed_in || !all_damaged_in {
		player_report_error(triplea_player, "Cannot remove enough units of those types")
		return casualty_selector_select_casualties(
			player,
			sorted_targets_to_pick_from,
			combat_value,
			battle_site,
			bridge,
			text,
			dice,
			battle_id,
			head_less,
			extra_hits,
			allow_multiple_hits_per_unit,
		)
	}

	return casualty_details
}
