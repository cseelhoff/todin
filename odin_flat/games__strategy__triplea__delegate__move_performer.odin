package game

import "core:fmt"

Move_Performer :: struct {
	move_delegate:           ^Abstract_Move_Delegate,
	bridge:                  ^IDelegate_Bridge,
	player:                  ^Game_Player,
	aa_in_move_util:         ^Aa_In_Move_Util,
	execution_stack:         ^Execution_Stack,
	current_move:            ^Undoable_Move,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
	arriving_units:          [dynamic]^Unit,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.MovePerformer

move_performer_lambda_mark_transports_movement_0 :: proc(u: ^Unit) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// games.strategy.triplea.delegate.MovePerformer#<init>()
//
//   MovePerformer() {}
//   private final ExecutionStack executionStack = new ExecutionStack();
move_performer_new :: proc() -> ^Move_Performer {
	self := new(Move_Performer)
	self.execution_stack = execution_stack_new()
	return self
}

// games.strategy.triplea.delegate.MovePerformer#getRemotePlayer(games.strategy.engine.data.GamePlayer)
//
//   return bridge.getRemotePlayer(gamePlayer);
move_performer_get_remote_player :: proc(self: ^Move_Performer, game_player: ^Game_Player) -> ^Player {
	return i_delegate_bridge_get_remote_player(self.bridge, game_player)
}

// games.strategy.triplea.delegate.MovePerformer#getRemotePlayer()
//
//   return getRemotePlayer(player);
move_performer_get_remote_player_no_args :: proc(self: ^Move_Performer) -> ^Player {
	return move_performer_get_remote_player(self, self.player)
}

// games.strategy.triplea.delegate.MovePerformer#initialize(AbstractMoveDelegate)
//
//   this.moveDelegate = delegate;
//   bridge = delegate.getBridge();
//   player = bridge.getGamePlayer();
//   if (aaInMoveUtil != null) { aaInMoveUtil.initialize(bridge); }
move_performer_initialize :: proc(self: ^Move_Performer, delegate: ^Abstract_Move_Delegate) {
	self.move_delegate = delegate
	self.bridge = abstract_move_delegate_get_bridge(delegate)
	self.player = i_delegate_bridge_get_game_player(self.bridge)
	if self.aa_in_move_util != nil {
		aa_in_move_util_initialize(self.aa_in_move_util, self.bridge)
	}
}

// games.strategy.triplea.delegate.MovePerformer#resume()
//
//   executionStack.execute(bridge);
move_performer_resume :: proc(self: ^Move_Performer) {
	execution_stack_execute(self.execution_stack, self.bridge)
}

// ---------------------------------------------------------------------------
// populateStack: three IExecutable closures pushed in reverse onto the stack.
// Java captures `units`, `route`, `gamePlayer`, `unitsToTransports`, and the
// enclosing MovePerformer; Odin closures are bare procs so each closure is
// modelled as a struct that embeds I_Executable and stores its captures.
// ---------------------------------------------------------------------------

Move_Performer_Pre_Aa_Fire :: struct {
	using base:        I_Executable,
	performer:         ^Move_Performer,
	units:             [dynamic]^Unit,
	route:             ^Route,
}

Move_Performer_Fire_Aa :: struct {
	using base:        I_Executable,
	performer:         ^Move_Performer,
	units:             [dynamic]^Unit,
	route:             ^Route,
}

Move_Performer_Post_Aa_Fire :: struct {
	using base:              I_Executable,
	performer:               ^Move_Performer,
	units:                   [dynamic]^Unit,
	route:                   ^Route,
	game_player:             ^Game_Player,
	units_to_transports:     map[^Unit]^Unit,
}

move_performer_pre_aa_fire_execute :: proc(self_base: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	self := cast(^Move_Performer_Pre_Aa_Fire)self_base
	performer := self.performer
	pending := battle_tracker_get_pending_battles_at_territory(
		move_performer_get_battle_tracker(performer),
		route_get_start(self.route),
	)
	defer delete(pending)
	for battle in pending {
		for unit in self.units {
			optional_route := abstract_move_delegate_get_route_used_to_move_into(
				abstract_move_delegate_get_undoable_moves(performer.move_delegate),
				unit,
				route_get_start(self.route),
			)
			if optional_route != nil {
				removed_units := make([dynamic]^Unit)
				append(&removed_units, unit)
				change := i_battle_remove_attack(battle, optional_route, removed_units)
				i_delegate_bridge_add_change(bridge, change)
				delete(removed_units)
			}
		}
	}
}

move_performer_fire_aa_execute :: proc(self_base: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	self := cast(^Move_Performer_Fire_Aa)self_base
	performer := self.performer
	aa_casualties := move_performer_fire_aa(performer, self.route, self.units)
	aa_casualties_with_dependents := make(map[^Unit]struct{})
	if aa_casualties != nil {
		for u in aa_casualties {
			aa_casualties_with_dependents[u] = {}
		}
		dependencies := transport_tracker_transporting_with_all_possible_units(self.units)
		for u in aa_casualties {
			deps, has := dependencies[u]
			if has {
				for d in deps {
					aa_casualties_with_dependents[d] = {}
				}
			}
			// we might have new dependents too (ie: paratroopers)
			air_deps, has_air := performer.air_transport_dependents[u]
			if has_air {
				for d in air_deps {
					aa_casualties_with_dependents[d] = {}
				}
			}
		}
	}
	// arrivingUnits = CollectionUtils.difference(units, aaCasualtiesWithDependents)
	performer.arriving_units = make([dynamic]^Unit)
	for u in self.units {
		if _, removed := aa_casualties_with_dependents[u]; !removed {
			append(&performer.arriving_units, u)
		}
	}
}

move_performer_post_aa_fire_execute :: proc(self_base: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	self := cast(^Move_Performer_Post_Aa_Fire)self_base
	performer := self.performer
	game_player := self.game_player
	data := i_delegate_bridge_get_data(bridge)
	must_fight_through_pred, must_fight_through_ctx := move_performer_get_must_fight_through_match(game_player)

	// arrived = intersection(units, arrivingUnits)
	arriving_set := make(map[^Unit]struct{})
	defer delete(arriving_set)
	for u in performer.arriving_units {
		arriving_set[u] = {}
	}
	arrived := make([dynamic]^Unit)
	for u in self.units {
		if _, in_arr := arriving_set[u]; in_arr {
			append(&arrived, u)
		}
	}
	// Reset
	performer.arriving_units = make([dynamic]^Unit)

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
	composite_change_add(change, route_get_fuel_changes(self.units, self.route, game_player, data))

	move_performer_mark_transports_movement(performer, arrived, transporting, self.route)

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
				move_performer_get_remote_player_no_args(performer),
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
						move_performer_get_remote_player_no_args(performer),
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
					battle_tracker_add_battle_bombing(
						move_performer_get_battle_tracker(performer),
						self.route,
						arrived_copy_for_battles,
						true,
						game_player,
						performer.bridge,
						performer.current_move,
						dependent_on_something_til_end,
						targets,
						false,
					)
				}
			}
		}

		// Ignore Trn on Trn forces.
		if properties_get_ignore_transport_in_movement(
			game_data_get_properties(i_delegate_bridge_get_data(performer.bridge)),
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
			battle_tracker_add_battle(
				move_performer_get_battle_tracker(performer),
				self.route,
				arrived_copy_for_battles,
				game_player,
				performer.bridge,
				performer.current_move,
				dependent_on_something_til_end,
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
					move_performer_get_battle_tracker(performer),
					t,
					game_player,
					performer.bridge,
					performer.current_move,
					arrived_copy_for_battles,
				)
			}
		}
	}

	// mark movement
	move_change := move_performer_mark_movement_change(performer, arrived, self.route, game_player)
	composite_change_add(change, move_change)
	// actually move the units
	remove_change := change_factory_remove_units(cast(^Unit_Holder)route_get_start(self.route), self.units)
	add_change := change_factory_add_units(cast(^Unit_Holder)route_get_end(self.route), arrived)
	composite_change_add(change, add_change, remove_change)
	i_delegate_bridge_add_change(performer.bridge, cast(^Change)change)
	undoable_move_add_change(performer.current_move, cast(^Change)change)
	desc := fmt.tprintf(
		"%s moved from %s to %s",
		my_formatter_units_to_text_no_owner(arrived),
		territory_to_string(route_get_start(self.route)),
		territory_to_string(route_get_end(self.route)),
	)
	undoable_move_set_description(performer.current_move, desc)
	abstract_move_delegate_update_undoable_moves(performer.move_delegate, performer.current_move)
}

// games.strategy.triplea.delegate.MovePerformer#populateStack(Collection,Route,GamePlayer,Map)
//
//   builds three IExecutable closures (preAaFire, fireAa, postAaFire),
//   pushes them in postAaFire→fireAa→preAaFire order, then executes.
move_performer_populate_stack :: proc(
	self: ^Move_Performer,
	units: [dynamic]^Unit,
	route: ^Route,
	game_player: ^Game_Player,
	units_to_transports: map[^Unit]^Unit,
) {
	pre := new(Move_Performer_Pre_Aa_Fire)
	pre.execute = move_performer_pre_aa_fire_execute
	pre.performer = self
	pre.units = units
	pre.route = route

	fire := new(Move_Performer_Fire_Aa)
	fire.execute = move_performer_fire_aa_execute
	fire.performer = self
	fire.units = units
	fire.route = route

	post := new(Move_Performer_Post_Aa_Fire)
	post.execute = move_performer_post_aa_fire_execute
	post.performer = self
	post.units = units
	post.route = route
	post.game_player = game_player
	post.units_to_transports = units_to_transports

	execution_stack_push_one(self.execution_stack, cast(^I_Executable)post)
	execution_stack_push_one(self.execution_stack, cast(^I_Executable)fire)
	execution_stack_push_one(self.execution_stack, cast(^I_Executable)pre)
	execution_stack_execute(self.execution_stack, self.bridge)
}

// games.strategy.triplea.delegate.MovePerformer#getBattleTracker()
//
//   return bridge.getData().getBattleDelegate().getBattleTracker();
move_performer_get_battle_tracker :: proc(self: ^Move_Performer) -> ^Battle_Tracker {
	return battle_delegate_get_battle_tracker(
		game_data_get_battle_delegate(i_delegate_bridge_get_data(self.bridge)),
	)
}

// games.strategy.triplea.delegate.MovePerformer#moveUnits(MoveDescription, GamePlayer, UndoableMove)
//
//   this.currentMove = currentMove;
//   this.airTransportDependents = move.getAirTransportsDependents();
//   populateStack(move.getUnits(), move.getRoute(), gamePlayer, move.getUnitsToSeaTransports());
//   executionStack.execute(bridge);
move_performer_move_units :: proc(
	self: ^Move_Performer,
	move: ^Move_Description,
	game_player: ^Game_Player,
	current_move: ^Undoable_Move,
) {
	self.current_move = current_move
	// Move_Description stores air-transport dependents as map-of-set; the
	// MovePerformer field uses map-of-list. Materialize each set as a list.
	src := move_description_get_air_transports_dependents(move)
	self.air_transport_dependents = make(map[^Unit][dynamic]^Unit)
	for k, set in src {
		arr := make([dynamic]^Unit)
		for u, _ in set {
			append(&arr, u)
		}
		self.air_transport_dependents[k] = arr
	}
	move_performer_populate_stack(
		self,
		move.units,
		move_description_get_route(move),
		game_player,
		move_description_get_units_to_sea_transports(move),
	)
	execution_stack_execute(self.execution_stack, self.bridge)
}


// games.strategy.triplea.delegate.MovePerformer#getMustFightThroughMatch(GamePlayer)
//
//   return Matches.isTerritoryEnemyAndNotUnownedWaterOrImpassableOrRestricted(gamePlayer)
//       .or(Matches.territoryHasNonSubmergedEnemyUnits(gamePlayer))
//       .or(Matches.isTerritoryNotUnownedWaterAndCanBeTakenOverBy(gamePlayer));
Move_Performer_Ctx_Get_Must_Fight_Through_Match :: struct {
	player: ^Game_Player,
}

move_performer_pred_get_must_fight_through_match :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Move_Performer_Ctx_Get_Must_Fight_Through_Match)ctx_ptr
	p1, c1 := matches_is_territory_enemy_and_not_unowned_water_or_impassable_or_restricted(c.player)
	if p1(c1, t) {
		return true
	}
	p2, c2 := matches_territory_has_non_submerged_enemy_units(c.player)
	if p2(c2, t) {
		return true
	}
	p3, c3 := matches_is_territory_not_unowned_water_and_can_be_taken_over_by(c.player)
	return p3(c3, t)
}

move_performer_get_must_fight_through_match :: proc(
	game_player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Move_Performer_Ctx_Get_Must_Fight_Through_Match)
	ctx.player = game_player
	return move_performer_pred_get_must_fight_through_match, rawptr(ctx)
}

// games.strategy.triplea.delegate.MovePerformer#hasConqueredNonBlitzed(Route)
//
//   final BattleTracker tracker = getBattleTracker();
//   for (final Territory current : route.getSteps()) {
//     if (tracker.wasConquered(current) && !tracker.wasBlitzed(current)) {
//       return true;
//     }
//   }
//   return false;
move_performer_has_conquered_non_blitzed :: proc(self: ^Move_Performer, route: ^Route) -> bool {
	tracker := move_performer_get_battle_tracker(self)
	steps := route_get_steps(route)
	defer delete(steps)
	for current in steps {
		if battle_tracker_was_conquered(tracker, current) && !battle_tracker_was_blitzed(tracker, current) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.MovePerformer#markMovementChange(Collection,Route,GamePlayer)
//
// Builds a CompositeChange that:
//   1. records the (possibly air-base-discounted) movement cost on every
//      unit owned by `game_player`,
//   2. zeroes movement of land units when the move was a combat move
//      crossing empty neutrals or non-blitzed conquered territory, and
//   3. zeroes movement of submarines/blockade-runners that ended a
//      non-combat move adjacent to enemy destroyers (when the
//      Subs Can End Non Combat Move With Enemies property is on).
move_performer_mark_movement_change :: proc(
	self: ^Move_Performer,
	units: [dynamic]^Unit,
	route: ^Route,
	game_player: ^Game_Player,
) -> ^Change {
	data := i_delegate_bridge_get_data(self.bridge)
	change := composite_change_new()
	// only units owned by us need to be marked
	relationship_tracker := game_data_get_relationship_tracker(data)
	route_start := route_get_start(route)
	route_end := route_get_end(route)
	owned_pred, owned_ctx := matches_unit_is_owned_by(game_player)
	for unit in units {
		if !owned_pred(owned_ctx, unit) {
			continue
		}
		moved := route_get_movement_cost(route, unit)
		ua := unit_get_unit_attachment(unit)
		if unit_attachment_is_air(ua) {
			if territory_attachment_has_air_base(route_start) &&
			   relationship_tracker_is_allied(
				   relationship_tracker,
				   territory_get_owner(route_start),
				   unit_get_owner(unit),
			   ) {
				moved -= 1.0
			}
			if route_end != nil &&
			   territory_attachment_has_air_base(route_end) &&
			   relationship_tracker_is_allied(
				   relationship_tracker,
				   territory_get_owner(route_end),
				   unit_get_owner(unit),
			   ) {
				moved -= 1.0
			}
		}
		boxed := new(f64)
		boxed^ = moved + unit_get_already_moved(unit)
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				unit,
				rawptr(boxed),
				.Already_Moved,
			),
		)
	}
	// if neutrals were taken over mark land units with 0 movement
	// if entered a non-blitzed conquered territory, mark with 0 movement
	if game_step_properties_helper_is_combat_move(data) {
		empty_neutral := move_delegate_get_empty_neutral(route)
		defer delete(empty_neutral)
		if len(empty_neutral) != 0 || move_performer_has_conquered_non_blitzed(self, route) {
			land_pred, land_ctx := matches_unit_is_land()
			for unit in units {
				if land_pred(land_ctx, unit) {
					composite_change_add(change, change_factory_mark_no_movement_change(unit))
				}
			}
		}
	}
	if route_end != nil &&
	   properties_get_subs_can_end_non_combat_move_with_enemies(game_data_get_properties(data)) &&
	   game_step_properties_helper_is_non_combat_move(data, false) {
		enemy_pred, enemy_ctx := matches_unit_is_enemy_of(game_player)
		destroyer_pred, destroyer_ctx := matches_unit_is_destroyer()
		end_units := unit_holder_get_units(cast(^Unit_Holder)route_end)
		defer delete(end_units)
		any_enemy_destroyer := false
		for u in end_units {
			if enemy_pred(enemy_ctx, u) && destroyer_pred(destroyer_ctx, u) {
				any_enemy_destroyer = true
				break
			}
		}
		if any_enemy_destroyer {
			move_through_pred, move_through_ctx := matches_unit_can_move_through_enemies()
			for unit in units {
				if move_through_pred(move_through_ctx, unit) {
					composite_change_add(change, change_factory_mark_no_movement_change(unit))
				}
			}
		}
	}
	return &change.change
}

// games.strategy.triplea.delegate.MovePerformer#fireAa(games.strategy.engine.data.Route,java.util.Collection)
//
//   if (aaInMoveUtil == null) aaInMoveUtil = new AaInMoveUtil();
//   aaInMoveUtil.initialize(bridge);
//   final Collection<Unit> unitsToRemove =
//       aaInMoveUtil.fireAa(
//           route, units, UnitComparator.getLowestToHighestMovementComparator(), currentMove);
//   aaInMoveUtil = null;
//   return unitsToRemove;
move_performer_fire_aa :: proc(
	self: ^Move_Performer,
	route: ^Route,
	units: [dynamic]^Unit,
) -> [dynamic]^Unit {
	if self.aa_in_move_util == nil {
		self.aa_in_move_util = aa_in_move_util_new()
	}
	aa_in_move_util_initialize(self.aa_in_move_util, self.bridge)
	cmp, cmp_ctx := unit_comparator_get_lowest_to_highest_movement_comparator()
	units_to_remove := aa_in_move_util_fire_aa(
		self.aa_in_move_util,
		route,
		units,
		cmp,
		cmp_ctx,
		self.current_move,
	)
	self.aa_in_move_util = nil
	return units_to_remove
}

// games.strategy.triplea.delegate.MovePerformer#markTransportsMovement(java.util.Collection,java.util.Map,games.strategy.engine.data.Route)
//
// Marks transports and units involved in unloading with no movement left.
// Mirrors the Java logic: build dependentAirTransportableUnits map (current
// arrivals + carry-over from airTransportDependents), then on a load route
// (or paratroopers landing) record load-transport changes; on an unload
// route (or paratroopers landing) unload non-air units (skipping
// paratroopers landing into combat/enemy territory until after AA fires)
// and zero their movement.
move_performer_mark_transports_movement :: proc(
	self: ^Move_Performer,
	arrived: [dynamic]^Unit,
	transporting: map[^Unit]^Unit,
	route: ^Route,
) {
	data := i_delegate_bridge_get_data(self.bridge)

	// Predicate: Matches.unitIsAirTransport().or(unitIsAirTransportable())
	at_pred,  at_ctx  := matches_unit_is_air_transport()
	atp_pred, atp_ctx := matches_unit_is_air_transportable()

	any_paratroop_or_air := false
	for u in arrived {
		if at_pred(at_ctx, u) || atp_pred(atp_ctx, u) {
			any_paratroop_or_air = true
			break
		}
	}
	paratroops_landing := any_paratroop_or_air &&
		move_validator_all_land_units_have_air_transport(arrived)

	dependent_air_transportable_units := make(map[^Unit][dynamic]^Unit)
	for unit in arrived {
		transport := unit_get_transported_by(unit)
		if transport != nil {
			arr, ok := dependent_air_transportable_units[transport]
			if !ok {
				arr = make([dynamic]^Unit)
			}
			append(&arr, unit)
			dependent_air_transportable_units[transport] = arr
		}
	}

	// add newly created dependents from airTransportDependents
	for k, v in self.air_transport_dependents {
		existing, ok := dependent_air_transportable_units[k]
		if ok {
			merged := make([dynamic]^Unit)
			for u in existing { append(&merged, u) }
			for u in v { append(&merged, u) }
			dependent_air_transportable_units[k] = merged
		} else {
			copied := make([dynamic]^Unit)
			for u in v { append(&copied, u) }
			dependent_air_transportable_units[k] = copied
		}
	}

	// load the transports
	if route_is_load(route) || paratroops_landing {
		// mark transports as having transported
		for load_unit, transporter in transporting {
			already_transport := unit_get_transported_by(load_unit)
			if already_transport != transporter {
				change := transport_tracker_load_transport_change(transporter, load_unit)
				undoable_move_add_change(self.current_move, change)
				undoable_move_load(self.current_move, transporter)
				i_delegate_bridge_add_change(self.bridge, change)
			}
		}
		if len(transporting) == 0 {
			for air_transport, transportable_units in dependent_air_transportable_units {
				for transportable_unit in transportable_units {
					change := transport_tracker_load_transport_change(air_transport, transportable_unit)
					undoable_move_add_change(self.current_move, change)
					undoable_move_load(self.current_move, air_transport)
					i_delegate_bridge_add_change(self.bridge, change)
				}
			}
		}
	}

	if route_is_unload(route) || paratroops_landing {
		// Set<Unit> units = transporting.values() ∪ transporting.keys()
		// (∪ dependent_air_transportable_units' keys+values when transporting is empty).
		units_set := make(map[^Unit]struct{})
		for k, v in transporting {
			units_set[k] = {}
			units_set[v] = {}
		}
		if len(transporting) == 0 {
			for k, v in dependent_air_transportable_units {
				units_set[k] = {}
				for u in v {
					units_set[u] = {}
				}
			}
		}

		// any pending battles in the unloading zone?
		tracker := move_performer_get_battle_tracker(self)
		pending_battles := battle_tracker_get_pending_battle(
			tracker,
			route_get_start(route),
			.NORMAL,
		) != nil

		air_pred, air_ctx           := matches_unit_is_air()
		ait_pred, ait_ctx           := matches_unit_is_air_transport()
		enemy_at_end_pred, enemy_at_end_ctx := matches_territory_has_non_submerged_enemy_units(self.player)

		for unit, _ in units_set {
			// CollectionUtils.getMatches(units, Matches.unitIsAir().negate())
			if air_pred(air_ctx, unit) {
				continue
			}
			transported_by := unit_get_transported_by(unit)
			// paratroopers landing in battle: unload after AA fires
			if paratroops_landing &&
			   transported_by != nil &&
			   ait_pred(ait_ctx, transported_by) &&
			   game_step_properties_helper_is_combat_move(data) &&
			   enemy_at_end_pred(enemy_at_end_ctx, route_get_end(route)) {
				continue
			}
			// unload the transports
			change1 := transport_tracker_unload_transport_change(
				unit,
				route_get_end(undoable_move_get_route(self.current_move)),
				pending_battles,
			)
			undoable_move_add_change(self.current_move, change1)
			undoable_move_unload(self.current_move, unit)
			i_delegate_bridge_add_change(self.bridge, change1)
			// set noMovement
			change2 := change_factory_mark_no_movement_change(unit)
			undoable_move_add_change(self.current_move, change2)
			i_delegate_bridge_add_change(self.bridge, change2)
		}
	}
}
