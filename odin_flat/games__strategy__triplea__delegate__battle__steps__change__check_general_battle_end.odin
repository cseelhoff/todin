package game

Check_General_Battle_End :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd

check_general_battle_end_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Check_General_Battle_End {
	self := new(Check_General_Battle_End)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

check_general_battle_end_get_all_step_details :: proc(
	self: ^Check_General_Battle_End,
) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

check_general_battle_end_get_battle_actions :: proc(
	self: ^Check_General_Battle_End,
) -> ^Battle_Actions {
	return self.battle_actions
}

check_general_battle_end_get_battle_state :: proc(
	self: ^Check_General_Battle_End,
) -> ^Battle_State {
	return self.battle_state
}

check_general_battle_end_get_order :: proc(
	self: ^Check_General_Battle_End,
) -> Battle_Step_Order {
	return .GENERAL_BATTLE_END_CHECK
}

check_general_battle_end_has_no_targets :: proc(
	self: ^Check_General_Battle_End,
	firing_groups: [dynamic]^Firing_Group,
) -> bool {
	return len(firing_groups) == 0
}

// Mirrors Java `Predicate<Unit> inAnyFiringGroup(Iterable<FiringGroup>)`.
// The returned rawptr is a heap-allocated capture of `firing_groups`
// to be passed alongside `check_general_battle_end_lambda_in_any_firing_group_1`.
check_general_battle_end_in_any_firing_group :: proc(
	self: ^Check_General_Battle_End,
	firing_groups: [dynamic]^Firing_Group,
) -> rawptr {
	captured := new([dynamic]^Firing_Group)
	captured^ = firing_groups
	return rawptr(captured)
}

check_general_battle_end_lambda_can_attacker_retreat_in_stalemate_2 :: proc(b: bool) -> bool {
	return b
}

check_general_battle_end_lambda_in_any_firing_group_1 :: proc(
	firing_groups: [dynamic]^Firing_Group,
	u: ^Unit,
) -> bool {
	for fg in firing_groups {
		for unit in fg.firing_units {
			if unit == u {
				return true
			}
		}
	}
	return false
}

// Mirrors javac-synthetic `lambda$inAnyFiringGroup$0`: the outer
// `Predicate<Unit>` body `u -> stream(firingGroups).anyMatch(fg -> fg.getFiringUnits().contains(u))`.
// The captured `firingGroups` arrives as a `rawptr` to a heap-allocated
// `[dynamic]^Firing_Group` (see `check_general_battle_end_in_any_firing_group`).
check_general_battle_end_lambda__in_any_firing_group__0 :: proc(
	ctx: rawptr,
	u: ^Unit,
) -> bool {
	firing_groups := (^[dynamic]^Firing_Group)(ctx)^
	for fg in firing_groups {
		for unit in fg.firing_units {
			if unit == u {
				return true
			}
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#hasSideLost
check_general_battle_end_has_side_lost :: proc(
	self: ^Check_General_Battle_End,
	side: Battle_State_Side,
) -> bool {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	units := battle_state_filter_units(self.battle_state, alive_filter, side)
	pred, ctx := matches_unit_is_not_infrastructure()
	for u in units {
		if pred(ctx, u) {
			return false
		}
	}
	return true
}

