package game

import "core:fmt"

Move_Performer_3 :: struct {
	using i_executable: I_Executable,
	outer: ^Move_Performer,
	game_player: ^Game_Player,
	units: [dynamic]^Unit,
	route: ^Route,
	units_to_transports: map[^Unit]^Unit,
}

move_performer_3_new :: proc(this0: ^Move_Performer, player: ^Game_Player, collection: [dynamic]^Unit, route: ^Route, the_map: map[^Unit]^Unit) -> ^Move_Performer_3 {
	self := new(Move_Performer_3)
	self.outer = this0
	self.game_player = player
	self.units = collection
	self.route = route
	self.units_to_transports = the_map
	self.i_executable.execute = move_performer_3_execute
	return self
}

// games.strategy.triplea.delegate.MovePerformer$3#execute(ExecutionStack, IDelegateBridge)
//
// postAaFire body: compute arrived units, mark transports, decide on battles
// (bombing raid / regular battle / non-combat take-over), then commit movement
// and unit add/remove changes.
move_performer_3_execute :: proc(self_base: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	_ = stack
	self := cast(^Move_Performer_3)self_base
	outer := self.outer
	game_player := self.game_player
	data := i_delegate_bridge_get_data(bridge)
	must_fight_through_pred, must_fight_through_ctx := move_performer_get_must_fight_through_match(game_player)

	// arrived = intersection(units, arrivingUnits)
	arriving_set := make(map[^Unit]struct{})
	defer delete(arriving_set)
	for u in outer.arriving_units {
		arriving_set[u] = {}
	}
	arrived := make([dynamic]^Unit)
	for u in self.units {
		if _, in_arr := arriving_set[u]; in_arr {
			append(&arrived, u)
		}
	}
	// Reset Optional
	outer.arriving_units = make([dynamic]^Unit)

	arrived_copy_for_battles := make([dynamic]^Unit)
	for u in arrived {
		append(&arrived_copy_for_battles, u)
	}

	transporting: map[^Unit]^Unit
	if route_is_load(self.route) {
		transporting = self.units_to_transports
	} else {
		transporting = transport_utils_map_transports(self.route, arrived, nil)
	}

	paratrooper_map := transport_utils_map_paratroopers(arrived)
	dependent_on_something_til_end := make(map[^Unit]struct{})
	for k, _ in paratrooper_map {
		dependent_on_something_til_end[k] = {}
	}

	present_from_start_til_end := make([dynamic]^Unit)
	for u in arrived {
		if _, dep := dependent_on_something_til_end[u]; !dep {
			append(&present_from_start_til_end, u)
		}
	}

	change := composite_change_new()

	// markFuelCostResourceChange must be done before we load/unload units
	composite_change_add(change, route_get_fuel_changes(self.units[:], self.route, game_player, data))

	move_performer_mark_transports_movement(outer, arrived, transporting, self.route)

	must_fight_through_match_any := false
	for step in self.route.steps {
		if must_fight_through_pred(must_fight_through_ctx, step) {
			must_fight_through_match_any = true
			break
		}
	}
	if len(arrived) > 0 && must_fight_through_match_any {
		ignore_battle := false
		// could it be a bombing raid
		enemy_unit_pred, enemy_unit_ctx := matches_enemy_unit(game_player)
		enemy_units := territory_get_matches(route_get_end(self.route), enemy_unit_pred, enemy_unit_ctx)

		can_be_damaged_pred, can_be_damaged_ctx := matches_unit_can_be_damaged()
		being_transported_pred, being_transported_ctx := matches_unit_is_being_transported()
		enemy_targets_total := make([dynamic]^Unit)
		for u in enemy_units {
			if can_be_damaged_pred(can_be_damaged_ctx, u) && !being_transported_pred(being_transported_ctx, u) {
				append(&enemy_targets_total, u)
			}
		}

		can_create_air_battle :=
			len(enemy_targets_total) > 0 &&
			properties_get_raids_may_be_preceeded_by_air_battles(game_data_get_properties(data)) &&
			air_battle_territory_could_possibly_have_air_battle_defenders(
				route_get_end(self.route), game_player, data, true,
			)

		strategic_bomber_pred, strategic_bomber_ctx := matches_unit_is_strategic_bomber()
		can_escort_pred, can_escort_ctx := matches_unit_can_escort()

		all_can_bomb := true
		for u in arrived {
			is_bomber := strategic_bomber_pred(strategic_bomber_ctx, u)
			is_escort := can_create_air_battle && can_escort_pred(can_escort_ctx, u)
			if !is_bomber && !is_escort {
				all_can_bomb = false
				break
			}
		}

		// strategic bombers among arrived
		strategic_bombers := make([dynamic]^Unit)
		for u in arrived {
			if strategic_bomber_pred(strategic_bomber_ctx, u) {
				append(&strategic_bombers, u)
			}
		}
		allowed_targets := unit_attachment_get_allowed_bombing_targets_intersection(
			strategic_bombers,
			game_data_get_unit_type_list(data),
		)
		of_types_pred, of_types_ctx := matches_unit_is_of_types(allowed_targets)
		enemy_targets := make([dynamic]^Unit)
		for u in enemy_targets_total {
			if of_types_pred(of_types_ctx, u) {
				append(&enemy_targets, u)
			}
		}

		all_escort := true
		for u in arrived {
			if !can_escort_pred(can_escort_ctx, u) {
				all_escort = false
				break
			}
		}
		targets_or_escort :=
			len(enemy_targets) > 0 ||
			(len(enemy_targets_total) > 0 && can_create_air_battle && all_escort)

		targeted_attack := false

		if all_can_bomb && targets_or_escort && game_step_properties_helper_is_combat_move(data) {
			bombing := player_should_bomber_bomb(
				move_performer_get_remote_player_no_args(outer),
				route_get_end(self.route),
			)
			if bombing {
				target: ^Unit
				if len(enemy_targets) > 1 &&
					properties_get_damage_from_bombing_done_to_units_instead_of_territories(
						game_data_get_properties(data),
					) &&
					!can_create_air_battle {
					target = player_what_should_bomber_bomb(
						move_performer_get_remote_player_no_args(outer),
						route_get_end(self.route),
						enemy_targets,
						arrived,
					)
				} else if len(enemy_targets) > 0 {
					target = enemy_targets[0]
				} else {
					// in case we are escorts only
					target = enemy_targets_total[0]
				}
				if target != nil {
					targeted_attack = true
					targets := make(map[^Unit]map[^Unit]struct{})
					arrived_set := make(map[^Unit]struct{})
					for u in arrived {
						arrived_set[u] = {}
					}
					targets[target] = arrived_set
					dep_til_end_list := make([dynamic]^Unit)
					defer delete(dep_til_end_list)
					for k, _ in dependent_on_something_til_end {
						append(&dep_til_end_list, k)
					}
					battle_tracker_add_battle(
						move_performer_get_battle_tracker(outer),
						self.route,
						arrived_copy_for_battles,
						true,
						game_player,
						outer.bridge,
						outer.current_move,
						dep_til_end_list,
						&targets,
						false,
					)
				}
			}
		}

		// Ignore Trn on Trn forces.
		if properties_get_ignore_transport_in_movement(
			game_data_get_properties(i_delegate_bridge_get_data(outer.bridge)),
		) {
			sea_transport_pred, sea_transport_ctx := matches_unit_is_sea_transport_but_not_combat_sea_transport()
			all_owned_transports := true
			for u in arrived {
				if !sea_transport_pred(sea_transport_ctx, u) {
					all_owned_transports = false
					break
				}
			}
			all_enemy_transports := len(enemy_units) > 0
			for u in enemy_units {
				if !sea_transport_pred(sea_transport_ctx, u) {
					all_enemy_transports = false
					break
				}
			}
			if all_owned_transports && all_enemy_transports {
				ignore_battle = true
			}
		}

		if !ignore_battle && game_step_properties_helper_is_combat_move(data) && !targeted_attack {
			dep_til_end_list2 := make([dynamic]^Unit)
			defer delete(dep_til_end_list2)
			for k, _ in dependent_on_something_til_end {
				append(&dep_til_end_list2, k)
			}
			battle_tracker_add_battle(
				move_performer_get_battle_tracker(outer),
				self.route,
				arrived_copy_for_battles,
				false,
				game_player,
				outer.bridge,
				outer.current_move,
				dep_til_end_list2,
				nil,
				false,
			)
		}

		if !ignore_battle &&
			game_step_properties_helper_is_non_combat_move(data, false) &&
			!targeted_attack {
			// non-combat: take over friendly territories
			can_take_over_pred, can_take_over_ctx := matches_is_territory_not_unowned_water_and_can_be_taken_over_by(game_player)
			blitzable_pred, blitzable_ctx := matches_territory_is_blitzable(game_player)
			matching_terrs := make([dynamic]^Territory)
			for step in self.route.steps {
				if can_take_over_pred(can_take_over_ctx, step) && blitzable_pred(blitzable_ctx, step) {
					append(&matching_terrs, step)
				}
			}
			enemy_terr_pred, enemy_terr_ctx := matches_is_territory_enemy(game_player)
			has_enemy_units_pred, has_enemy_units_ctx := matches_territory_has_enemy_units(game_player)
			air_pred, air_ctx := matches_unit_is_air()

			for t in matching_terrs {
				if enemy_terr_pred(enemy_terr_ctx, t) || has_enemy_units_pred(has_enemy_units_ctx, t) {
					continue
				}
				is_end := t == route_get_end(self.route)
				all_air_arrived := len(arrived_copy_for_battles) > 0
				for u in arrived_copy_for_battles {
					if !air_pred(air_ctx, u) {
						all_air_arrived = false
						break
					}
				}
				all_air_present := len(present_from_start_til_end) > 0
				for u in present_from_start_til_end {
					if !air_pred(air_ctx, u) {
						all_air_present = false
						break
					}
				}
				if (is_end && len(arrived_copy_for_battles) > 0 && all_air_arrived) ||
					(!is_end && len(present_from_start_til_end) > 0 && all_air_present) {
					continue
				}
				battle_tracker_take_over(
					move_performer_get_battle_tracker(outer),
					t,
					game_player,
					outer.bridge,
					outer.current_move,
					arrived_copy_for_battles,
				)
			}
		}
	}

	// mark movement
	move_change := move_performer_mark_movement_change(outer, arrived, self.route, game_player)
	composite_change_add(change, move_change)
	// actually move the units
	remove_change := change_factory_remove_units(cast(^Unit_Holder)route_get_start(self.route), self.units)
	add_change := change_factory_add_units(cast(^Unit_Holder)route_get_end(self.route), arrived)
	composite_change_add(change, add_change, remove_change)
	i_delegate_bridge_add_change(outer.bridge, cast(^Change)change)
	undoable_move_add_change(outer.current_move, cast(^Change)change)
	desc := fmt.tprintf(
		"%s moved from %s to %s",
		my_formatter_units_to_text_no_owner(arrived, nil),
		territory_to_string(route_get_start(self.route)),
		territory_to_string(route_get_end(self.route)),
	)
	undoable_move_set_description(outer.current_move, desc)
	abstract_move_delegate_update_undoable_moves(outer.move_delegate, outer.current_move)
}

