package game

Aa_Casualty_Selector :: struct {}

aa_casualty_selector_lambda_build_casualty_details_0 :: proc(
	casualty_details: ^Casualty_Details,
	unit: ^Unit,
	unit_key: ^Unit,
	hp: i64,
) -> i64 {
	if hp > 1 {
		casualty_list_add_to_damaged(&casualty_details.casualty_list, unit)
	} else {
		casualty_list_add_to_killed(&casualty_details.casualty_list, unit)
	}
	return hp - 1
}

