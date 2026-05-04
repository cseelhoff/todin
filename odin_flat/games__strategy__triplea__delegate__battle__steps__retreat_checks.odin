package game

Retreat_Checks :: struct {}

retreat_checks_can_attacker_retreat :: proc(
	defending_units: [dynamic]^Unit,
	game_data: ^Game_State,
	get_attacker_retreat_territories: proc() -> [dynamic]^Territory,
	is_amphibious: bool,
) -> bool {
	if is_amphibious {
		return false
	}
	if retreat_checks_only_defenseless_transports_left(defending_units, game_data) {
		return false
	}
	return len(get_attacker_retreat_territories()) > 0
}

retreat_checks_only_defenseless_transports_left :: proc(units: [dynamic]^Unit, game_data: ^Game_State) -> bool {
	if !properties_get_transport_casualties_restricted(game_state_get_properties(game_data)) {
		return false
	}
	if len(units) == 0 {
		return false
	}
	pred, ctx := matches_unit_is_sea_transport_but_not_combat_sea_transport()
	for u in units {
		if !pred(ctx, u) {
			return false
		}
	}
	return true
}
