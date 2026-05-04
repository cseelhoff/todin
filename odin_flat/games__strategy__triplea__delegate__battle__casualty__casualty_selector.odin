package game

Casualty_Selector :: struct {}

casualty_selector_clear_ool_cache :: proc() {
	casualty_order_of_losses_clear_ool_cache()
}

casualty_selector_lambda_select_casualties_0 :: proc(u: ^Unit) -> bool {
	return unit_attachment_get_is_marine(unit_get_unit_attachment(u)) != 0 &&
		unit_get_was_amphibious(u)
}
