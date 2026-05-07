package game

Mark_No_Movement_Left :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

mark_no_movement_left_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return mark_no_movement_left_get_all_step_details(cast(^Mark_No_Movement_Left)self)
}

mark_no_movement_left_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	mark_no_movement_left_execute(cast(^Mark_No_Movement_Left)self, stack, bridge)
}

mark_no_movement_left_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Mark_No_Movement_Left {
	self := new(Mark_No_Movement_Left)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.get_all_step_details = mark_no_movement_left_v_get_all_step_details
	self.get_order = mark_no_movement_left_v_get_order
	self.execute = mark_no_movement_left_v_execute
	return self
}

mark_no_movement_left_v_get_order :: proc(self: ^Battle_Step) -> Battle_Step_Order {
	return mark_no_movement_left_get_order(cast(^Mark_No_Movement_Left)self)
}

mark_no_movement_left_get_all_step_details :: proc(self: ^Mark_No_Movement_Left) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

mark_no_movement_left_get_order :: proc(self: ^Mark_No_Movement_Left) -> Battle_Step_Order {
	return .MARK_NO_MOVEMENT_LEFT
}

// Java: MarkNoMovementLeft#execute(ExecutionStack, IDelegateBridge)
//   if (battleState.getStatus().isFirstRound() && !battleState.getStatus().isHeadless()) {
//     final Collection<Unit> attackingNonAir =
//         CollectionUtils.getMatches(
//             battleState.filterUnits(ALIVE, OFFENSE), Matches.unitIsAir().negate());
//     final Change noMovementChange = ChangeFactory.markNoMovementChange(attackingNonAir);
//     if (!noMovementChange.isEmpty()) bridge.addChange(noMovementChange);
//   }
// `collection_utils_get_matches` takes `proc(rawptr) -> bool`, but
// `matches_unit_is_air` returns the rawptr-ctx pair form; following
// the convention in air_that_cant_land_util.odin we filter inline.
mark_no_movement_left_execute :: proc(
	self: ^Mark_No_Movement_Left,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	status := battle_state_get_status(self.battle_state)
	if battle_status_is_first_round(status) && !battle_status_is_headless(status) {
		alive_filter := battle_state_unit_battle_filter_new(.Alive)
		alive_offense := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
		defer delete(alive_offense)
		air_pred, air_ctx := matches_unit_is_air()
		attacking_non_air := make([dynamic]^Unit, 0, len(alive_offense))
		for u in alive_offense {
			if !air_pred(air_ctx, u) {
				append(&attacking_non_air, u)
			}
		}
		no_movement_change := change_factory_mark_no_movement_change_collection(attacking_non_air)
		delete(attacking_non_air)
		if !change_is_empty(no_movement_change) {
			i_delegate_bridge_add_change(bridge, no_movement_change)
		}
	}
}

