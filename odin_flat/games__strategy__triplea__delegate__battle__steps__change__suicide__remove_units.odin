package game

Suicide_Remove_Units :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.suicide.RemoveUnits

suicide_remove_units_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Suicide_Remove_Units {
	self := new(Suicide_Remove_Units)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

suicide_remove_units_get_dependents :: proc(self: ^Suicide_Remove_Units, units: [dynamic]^Unit) -> map[^Unit][dynamic]^Unit {
	dependents := make(map[^Unit][dynamic]^Unit)
	for unit in units {
		single := make([dynamic]^Unit)
		append(&single, unit)
		dependents[unit] = battle_state_get_dependent_units(self.battle_state, single)
	}
	return dependents
}

// AND-adapter so we can combine the caller's predicate with the
// suicide-on-attack / suicide-on-defense match (Java: `unitMatch.and(...)`).
Suicide_Remove_Units_And_Ctx :: struct {
	a:     proc(rawptr, ^Unit) -> bool,
	a_ctx: rawptr,
	b:     proc(rawptr, ^Unit) -> bool,
	b_ctx: rawptr,
}

suicide_remove_units_and_pred :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Suicide_Remove_Units_And_Ctx)ctx_ptr
	return c.a(c.a_ctx, u) && c.b(c.b_ctx, u)
}

// Java: RemoveUnits#removeSuicideUnits(IDelegateBridge, Predicate<Unit>, Side)
suicide_remove_units_remove_suicide_units :: proc(
	self: ^Suicide_Remove_Units,
	bridge: ^I_Delegate_Bridge,
	unit_match: proc(rawptr, ^Unit) -> bool,
	unit_match_ctx: rawptr,
	side: Battle_State_Side,
) {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	candidates := battle_state_filter_units(self.battle_state, alive_filter, side)

	side_pred:    proc(rawptr, ^Unit) -> bool
	side_pred_ctx: rawptr
	if side == .OFFENSE {
		side_pred, side_pred_ctx = matches_unit_is_suicide_on_attack()
	} else {
		side_pred, side_pred_ctx = matches_unit_is_suicide_on_defense()
	}

	combined_ctx := new(Suicide_Remove_Units_And_Ctx)
	combined_ctx.a = unit_match
	combined_ctx.a_ctx = unit_match_ctx
	combined_ctx.b = side_pred
	combined_ctx.b_ctx = side_pred_ctx

	suicide_units := make([dynamic]^Unit)
	for u in candidates {
		if suicide_remove_units_and_pred(combined_ctx, u) {
			append(&suicide_units, u)
		}
	}

	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_dead_unit_notification(
		display,
		battle_state_get_battle_id(self.battle_state),
		battle_state_get_player(self.battle_state, side),
		suicide_units,
		suicide_remove_units_get_dependents(self, suicide_units),
	)

	battle_actions_remove_units(
		self.battle_actions,
		suicide_units,
		bridge,
		battle_state_get_battle_site(self.battle_state),
		side,
	)
}

