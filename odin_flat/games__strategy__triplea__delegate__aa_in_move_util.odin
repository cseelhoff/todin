package game

Aa_In_Move_Util :: struct {
	bridge:          ^I_Delegate_Bridge,
	player:          ^Game_Player,
	casualties:      [dynamic]^Unit,
	execution_stack: ^Execution_Stack,
}

// games.strategy.triplea.delegate.AaInMoveUtil#<init>()
aa_in_move_util_new :: proc() -> ^Aa_In_Move_Util {
	self := new(Aa_In_Move_Util)
	self.casualties = make([dynamic]^Unit)
	self.execution_stack = execution_stack_new()
	return self
}

// games.strategy.triplea.delegate.AaInMoveUtil#getData()
aa_in_move_util_get_data :: proc(self: ^Aa_In_Move_Util) -> ^Game_Data {
	return i_delegate_bridge_get_data(self.bridge)
}

// games.strategy.triplea.delegate.AaInMoveUtil#initialize(games.strategy.engine.delegate.IDelegateBridge)
aa_in_move_util_initialize :: proc(self: ^Aa_In_Move_Util, bridge: ^I_Delegate_Bridge) {
	self.bridge = bridge
	self.player = i_delegate_bridge_get_game_player(bridge)
}

// games.strategy.triplea.delegate.AaInMoveUtil#movingPlayer(java.util.Collection)
aa_in_move_util_moving_player :: proc(self: ^Aa_In_Move_Util, units: [dynamic]^Unit) -> ^Game_Player {
	for u in units {
		if u != nil && unit_is_owned_by(u, self.player) {
			return self.player
		}
	}
	for u in units {
		if u == nil {
			continue
		}
		owner := unit_get_owner(u)
		if owner != nil {
			return owner
		}
	}
	return player_list_get_null_player(game_data_get_player_list(game_player_get_data(self.player)))
}

// games.strategy.triplea.delegate.AaInMoveUtil#getBattleTracker()
aa_in_move_util_get_battle_tracker :: proc(self: ^Aa_In_Move_Util) -> ^Battle_Tracker {
	return battle_delegate_get_battle_tracker(game_data_get_battle_delegate(aa_in_move_util_get_data(self)))
}

// games.strategy.triplea.delegate.AaInMoveUtil#getTerritoriesWhereAaWillFire(games.strategy.engine.data.Route,java.util.Collection)
aa_in_move_util_get_territories_where_aa_will_fire :: proc(
	self: ^Aa_In_Move_Util,
	route: ^Route,
	units: [dynamic]^Unit,
) -> [dynamic]^Territory {
	data := aa_in_move_util_get_data(self)
	props := game_data_get_properties(data)
	always_on_aa := properties_get_always_on_aa(props)
	if !always_on_aa && properties_get_aa_territory_restricted(props) {
		return make([dynamic]^Territory)
	}
	// No AA in nonCombat unless 'Always on AA'
	if game_step_properties_helper_is_non_combat_move(data, false) && !always_on_aa {
		return make([dynamic]^Territory)
	}
	moving_player := aa_in_move_util_moving_player(self, units)
	tech_advances := tech_tracker_get_current_tech_advances(
		moving_player,
		game_data_get_technology_frontier(data),
	)
	defer delete(tech_advances)
	airborne_tech_targets_allowed :=
		tech_ability_attachment_get_airborne_targetted_by_aa_with_techs(tech_advances)
	type_of_aa, type_of_aa_ctx := matches_unit_is_aa_for_fly_over_only()
	has_aa, has_aa_ctx := matches_unit_is_aa_that_can_fire(
		units,
		airborne_tech_targets_allowed,
		moving_player,
		type_of_aa,
		type_of_aa_ctx,
		1,
		true,
	)
	territories_where_aa_will_fire := make([dynamic]^Territory)
	middle_steps := route_get_middle_steps(route)
	defer delete(middle_steps)
	for current in middle_steps {
		if territory_any_units_match(current, has_aa, has_aa_ctx) {
			append(&territories_where_aa_will_fire, current)
		}
	}
	if properties_get_force_aa_attacks_for_last_step_of_fly_over(props) {
		end := route_get_end(route)
		if territory_any_units_match(end, has_aa, has_aa_ctx) {
			append(&territories_where_aa_will_fire, end)
		}
	} else {
		start := route_get_start(route)
		if territory_any_units_match(start, has_aa, has_aa_ctx) &&
		   !battle_tracker_was_battle_fought(aa_in_move_util_get_battle_tracker(self), start) {
			append(&territories_where_aa_will_fire, start)
		}
	}
	return territories_where_aa_will_fire
}

// games.strategy.triplea.delegate.AaInMoveUtil#populateExecutionStack(games.strategy.engine.data.Route,java.util.Collection,java.util.Comparator,games.strategy.triplea.delegate.UndoableMove)
//
// Java's `Comparator<Unit> decreasingMovement` is modeled as the
// closure-capable pair (less-proc + rawptr ctx). The proc returns
// true when its first argument should sort strictly before the
// second (i.e. Java's `compare(a, b) < 0`). Java's
// `targets.sort(decreasingMovement)` becomes an in-place insertion
// sort over the captured comparator, matching the convention used
// elsewhere in the port (see pro_transport_utils).
aa_in_move_util_populate_execution_stack :: proc(
	self: ^Aa_In_Move_Util,
	route: ^Route,
	units: [dynamic]^Unit,
	decreasing_movement: proc(rawptr, ^Unit, ^Unit) -> bool,
	decreasing_movement_ctx: rawptr,
	current_move: ^Undoable_Move,
) {
	// final List<Unit> targets = new ArrayList<>(units);
	targets := make([dynamic]^Unit)
	for u in units {
		append(&targets, u)
	}
	// targets.sort(decreasingMovement);
	for i := 1; i < len(targets); i += 1 {
		j := i
		for j > 0 && decreasing_movement(decreasing_movement_ctx, targets[j], targets[j - 1]) {
			tmp := targets[j]
			targets[j] = targets[j - 1]
			targets[j - 1] = tmp
			j -= 1
		}
	}

	executables := make([dynamic]^I_Executable)
	defer delete(executables)
	territories := aa_in_move_util_get_territories_where_aa_will_fire(self, route, units)
	defer delete(territories)
	for location in territories {
		ie := aa_in_move_util_3_new(self, location, targets, current_move)
		append(&executables, cast(^I_Executable)ie)
	}
	// Collections.reverse(executables);
	n := len(executables)
	for i := 0; i < n / 2; i += 1 {
		tmp := executables[i]
		executables[i] = executables[n - 1 - i]
		executables[n - 1 - i] = tmp
	}
	execution_stack_push_all(self.execution_stack, executables[:])
}
