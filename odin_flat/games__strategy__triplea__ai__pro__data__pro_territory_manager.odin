package game

Pro_Territory_Manager :: struct {
	calc:                     ^Pro_Odds_Calculator,
	pro_data:                 ^Pro_Data,
	player:                   ^Game_Player,
	attack_options:           ^Pro_My_Move_Options,
	potential_attack_options: ^Pro_My_Move_Options,
	defend_options:           ^Pro_My_Move_Options,
	allied_attack_options:    ^Pro_Other_Move_Options,
	enemy_defend_options:     ^Pro_Other_Move_Options,
	enemy_attack_options:     ^Pro_Other_Move_Options,
}

pro_territory_manager_get_attack_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_My_Move_Options {
	return self.attack_options
}

pro_territory_manager_get_defend_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_My_Move_Options {
	return self.defend_options
}

pro_territory_manager_get_allied_attack_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_Other_Move_Options {
	return self.allied_attack_options
}

pro_territory_manager_get_enemy_defend_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_Other_Move_Options {
	return self.enemy_defend_options
}

pro_territory_manager_get_enemy_attack_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_Other_Move_Options {
	return self.enemy_attack_options
}

// Lambda: findNavalMoveOptions  transportMoveMap.computeIfAbsent(mySeaUnit, k -> new HashSet<>())
pro_territory_manager_lambda_find_naval_move_options_1 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findNavalMoveOptions  unitMoveMap.computeIfAbsent(mySeaUnit, k -> new HashSet<>())
pro_territory_manager_lambda_find_naval_move_options_2 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findLandMoveOptions  landRoutesMap.computeIfAbsent(t, k -> new HashSet<>())
pro_territory_manager_lambda_find_land_move_options_3 :: proc(k: ^Territory) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findLandMoveOptions  unitMoveMap.computeIfAbsent(u, k -> new HashSet<>())
pro_territory_manager_lambda_find_land_move_options_4 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findAirMoveOptions  unitMoveMap.computeIfAbsent(myAirUnit, k -> new HashSet<>())
pro_territory_manager_lambda_find_air_move_options_5 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findBombardOptions  bombardMap.computeIfAbsent(mySeaUnit, k -> new HashSet<>())
pro_territory_manager_lambda_find_bombard_options_7 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findClosestTerritory  bfs.traverse((territory, distance) -> { ... })
// Captures Predicate<Territory> isDestination and MutableObject<Territory> destination,
// passed explicitly as leading parameters per Java desugaring. Predicate uses the
// (proc, ctx) closure-capture convention; MutableObject<Territory> is modeled as ^^Territory.
pro_territory_manager_lambda_find_closest_territory_8 :: proc(
	is_destination: proc(rawptr, ^Territory) -> bool,
	is_destination_ctx: rawptr,
	destination: ^^Territory,
	territory: ^Territory,
	distance: i32,
) -> bool {
	if is_destination(is_destination_ctx, territory) {
		destination^ = territory
		return false
	}
	return true
}

