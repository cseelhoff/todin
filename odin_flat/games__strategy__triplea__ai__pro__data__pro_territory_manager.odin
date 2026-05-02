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

pro_territory_manager_new :: proc(calc: ^Pro_Odds_Calculator, pro_data: ^Pro_Data) -> ^Pro_Territory_Manager {
	self := new(Pro_Territory_Manager)
	self.calc = calc
	self.pro_data = pro_data
	self.player = pro_data_get_player(pro_data)
	self.attack_options = pro_my_move_options_new()
	self.potential_attack_options = pro_my_move_options_new()
	self.defend_options = pro_my_move_options_new()
	self.allied_attack_options = pro_other_move_options_new()
	self.enemy_defend_options = pro_other_move_options_new()
	self.enemy_attack_options = pro_other_move_options_new()
	return self
}

pro_territory_manager_find_bombing_options :: proc(self: ^Pro_Territory_Manager) {
	pred, ctx := matches_unit_is_strategic_bomber()
	unit_move_map := pro_my_move_options_get_unit_move_map(self.attack_options)
	bomber_move_map := pro_my_move_options_get_bomber_move_map(self.attack_options)
	for unit, dests in unit_move_map {
		if pred(ctx, unit) {
			copy_set := make(map[^Territory]struct {})
			for t, _ in dests {
				copy_set[t] = struct {}{}
			}
			bomber_move_map[unit] = copy_set
		}
	}
}

pro_territory_manager_get_defend_territories :: proc(self: ^Pro_Territory_Manager) -> [dynamic]^Territory {
	result: [dynamic]^Territory
	territory_map := pro_my_move_options_get_territory_map(self.defend_options)
	for t, _ in territory_map {
		append(&result, t)
	}
	return result
}

pro_territory_manager_get_strafing_territories :: proc(self: ^Pro_Territory_Manager) -> [dynamic]^Territory {
	strafing_territories: [dynamic]^Territory
	territory_map := pro_my_move_options_get_territory_map(self.attack_options)
	for t, patd in territory_map {
		if pro_territory_is_strafing(patd) {
			append(&strafing_territories, t)
		}
	}
	return strafing_territories
}

pro_territory_manager_get_cant_hold_territories :: proc(self: ^Pro_Territory_Manager) -> [dynamic]^Territory {
	territories_that_cant_be_held: [dynamic]^Territory
	territory_map := pro_my_move_options_get_territory_map(self.defend_options)
	for t, patd in territory_map {
		if !pro_territory_is_can_hold(patd) {
			append(&territories_that_cant_be_held, t)
		}
	}
	return territories_that_cant_be_held
}

pro_territory_manager_have_used_all_attack_transports :: proc(self: ^Pro_Territory_Manager) -> bool {
	moved_transports: map[^Unit]struct {}
	territory_map := pro_my_move_options_get_territory_map(self.attack_options)
	is_sea_transport, is_sea_transport_ctx := matches_unit_is_sea_transport()
	for _, patd in territory_map {
		amphib := pro_territory_get_amphib_attack_map(patd)
		for u in amphib {
			moved_transports[u] = {}
		}
		units := pro_territory_get_units(patd)
		for u in units {
			if is_sea_transport(is_sea_transport_ctx, u) {
				moved_transports[u] = {}
			}
		}
	}
	transport_list := pro_my_move_options_get_transport_list(self.attack_options)
	return len(moved_transports) >= len(transport_list)
}

