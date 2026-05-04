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

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#<init>(ProOddsCalculator, ProData, ProTerritoryManager)
// Java copy-style constructor: delegates to the (calc, proData) ctor, then
// rebuilds the Pro_My_Move_Options via their copy ctor and shares the
// other-move-options refs from the source manager.
pro_territory_manager_new_with_existing :: proc(
	calc: ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
	territory_manager: ^Pro_Territory_Manager,
) -> ^Pro_Territory_Manager {
	self := pro_territory_manager_new(calc, pro_data)
	self.attack_options = pro_my_move_options_new_copy(territory_manager.attack_options, pro_data)
	self.potential_attack_options = pro_my_move_options_new_copy(
		territory_manager.potential_attack_options,
		pro_data,
	)
	self.defend_options = pro_my_move_options_new_copy(territory_manager.defend_options, pro_data)
	self.allied_attack_options = pro_territory_manager_get_allied_attack_options(territory_manager)
	self.enemy_defend_options = pro_territory_manager_get_enemy_defend_options(territory_manager)
	self.enemy_attack_options = pro_territory_manager_get_enemy_attack_options(territory_manager)
	return self
}

// File-scope holder bridging two ctx-form Predicate<Territory> values
// (canMove and isDestination) into the BiPredicate-shaped neighborCondition
// that BreadthFirstSearch consumes. BFS is single-threaded and constructed-
// then-traversed, matching the holder pattern used by breadth_first_search.odin.
@(private = "file")
pro_territory_manager_find_closest_territory_active_can_move: proc(
	ctx: rawptr,
	t: ^Territory,
) -> bool

@(private = "file")
pro_territory_manager_find_closest_territory_active_can_move_ctx: rawptr

@(private = "file")
pro_territory_manager_find_closest_territory_active_is_destination: proc(
	ctx: rawptr,
	t: ^Territory,
) -> bool

@(private = "file")
pro_territory_manager_find_closest_territory_active_is_destination_ctx: rawptr

@(private = "file")
pro_territory_manager_find_closest_territory_or_predicate :: proc(
	it: ^Territory,
	it2: ^Territory,
) -> bool {
	if pro_territory_manager_find_closest_territory_active_can_move(
		pro_territory_manager_find_closest_territory_active_can_move_ctx,
		it2,
	) {
		return true
	}
	return pro_territory_manager_find_closest_territory_active_is_destination(
		pro_territory_manager_find_closest_territory_active_is_destination_ctx,
		it2,
	)
}

// Visitor adapter for the bfs.traverse lambda inside findClosestTerritory.
// Captures the isDestination Predicate (ctx-form) and the MutableObject<Territory>
// out-param (modeled as ^^Territory) so the synthetic
// pro_territory_manager_lambda_find_closest_territory_8 can be invoked from
// the Breadth_First_Search_Visitor vtable slot.
Pro_Territory_Manager_Find_Closest_Territory_Visitor :: struct {
	using visitor:      Breadth_First_Search_Visitor,
	is_destination:     proc(ctx: rawptr, t: ^Territory) -> bool,
	is_destination_ctx: rawptr,
	destination:        ^^Territory,
}

@(private = "file")
pro_territory_manager_find_closest_territory_visit :: proc(
	self: ^Breadth_First_Search_Visitor,
	territory: ^Territory,
	distance: i32,
) -> bool {
	me := cast(^Pro_Territory_Manager_Find_Closest_Territory_Visitor)self
	return pro_territory_manager_lambda_find_closest_territory_8(
		me.is_destination,
		me.is_destination_ctx,
		me.destination,
		territory,
		distance,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findClosestTerritory(Collection, Predicate, Predicate)
// Java:
//   BreadthFirstSearch bfs = new BreadthFirstSearch(fromTerritories, canMove.or(isDestination));
//   MutableObject<Territory> destination = new MutableObject<>();
//   bfs.traverse((territory, distance) -> { if (isDestination.test(territory)) { destination.setValue(territory); return false; } return true; });
//   return Optional.ofNullable(destination.getValue());
//
// Optional<Territory> is modeled as a (possibly nil) ^Territory return.
pro_territory_manager_find_closest_territory :: proc(
	self: ^Pro_Territory_Manager,
	from_territories: [dynamic]^Territory,
	can_move: proc(ctx: rawptr, t: ^Territory) -> bool,
	can_move_ctx: rawptr,
	is_destination: proc(ctx: rawptr, t: ^Territory) -> bool,
	is_destination_ctx: rawptr,
) -> ^Territory {
	pro_territory_manager_find_closest_territory_active_can_move = can_move
	pro_territory_manager_find_closest_territory_active_can_move_ctx = can_move_ctx
	pro_territory_manager_find_closest_territory_active_is_destination = is_destination
	pro_territory_manager_find_closest_territory_active_is_destination_ctx = is_destination_ctx
	bfs := breadth_first_search_new(
		from_territories,
		pro_territory_manager_find_closest_territory_or_predicate,
	)
	destination: ^Territory = nil
	visitor := new(Pro_Territory_Manager_Find_Closest_Territory_Visitor)
	visitor.visit = pro_territory_manager_find_closest_territory_visit
	visitor.is_destination = is_destination
	visitor.is_destination_ctx = is_destination_ctx
	visitor.destination = &destination
	breadth_first_search_traverse(bfs, &visitor.visitor)
	return destination
}

// Lambda: findAmphibMoveOptions  canBeTransported.and(u -> u.getUnitAttachment().getTransportCost() <= capacity)
// Captures the local int `capacity`; per Java desugaring the captured value
// is supplied as the leading parameter of the synthetic lambda$N.
pro_territory_manager_lambda_find_amphib_move_options_6 :: proc(
	capacity: i32,
	u: ^Unit,
) -> bool {
	return unit_attachment_get_transport_cost(unit_get_unit_attachment(u)) <= capacity
}

