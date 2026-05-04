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
