package game

Battle_Step :: struct {
	using i_executable: I_Executable,

	// games.strategy.triplea.delegate.battle.steps.BattleStep#getAllStepDetails()
	// Default impl returns an empty list per BattleStep's
	// `default List<StepDetails> getAllStepDetails() { return List.of(); }`.
	// Concrete subtypes that override this assign their own thunk in
	// their `_new` constructor.
	get_all_step_details: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details,

	// games.strategy.triplea.delegate.battle.steps.BattleStep#getOrder()
	// No default in Java; every concrete subtype implements it. Each
	// subtype's `_new` constructor wires its own `*_v_get_order` adapter.
	get_order: proc(self: ^Battle_Step) -> Battle_Step_Order,
}

// Public dispatch proc for getAllStepDetails(). Falls back to an empty
// list when the field is nil (matches the Java default method).
battle_step_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	if self.get_all_step_details != nil {
		return self.get_all_step_details(self)
	}
	out: [dynamic]^Battle_Step_Step_Details
	return out
}

// Public dispatch proc for getOrder(). Mirrors Java's `BattleStep::getOrder`
// virtual dispatch. Every concrete subtype must wire `get_order` in its
// constructor; if a subtype is missing a wiring this will return the
// zero value (AA_OFFENSIVE) — that is a porting bug, not a default.
battle_step_get_order :: proc(self: ^Battle_Step) -> Battle_Step_Order {
	if self.get_order != nil {
		return self.get_order(self)
	}
	return Battle_Step_Order.AA_OFFENSIVE
}

// Java: static List<BattleStep> BattleStep.getAll(BattleState, BattleActions)
//
// Returns the canonical ordered list of every concrete battle step.
// Ordering matches the Java `List.of(...)` literal verbatim so that
// downstream consumers (e.g. BattleSteps#getSteps) observe the same
// sequence regardless of language. Each element is a freshly allocated
// subtype whose embedded `Battle_Step` is exposed via Odin's transitive
// `using`, so `&x.battle_step` yields a `^Battle_Step` pointing at the
// shared base record.
battle_step_get_all :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> [dynamic]^Battle_Step {
	out := make([dynamic]^Battle_Step, 0, 24)
	append(&out, &offensive_aa_fire_new(battle_state, battle_actions).battle_step)
	append(&out, &defensive_aa_fire_new(battle_state, battle_actions).battle_step)
	append(&out, &submerge_subs_vs_only_air_step_new(battle_state, battle_actions).battle_step)
	append(&out, &remove_unprotected_units_new(battle_state, battle_actions).battle_step)
	append(&out, &naval_bombardment_new(battle_state, battle_actions).battle_step)
	append(&out, &clear_bombardment_casualties_new(battle_state, battle_actions).battle_step)
	append(&out, &land_paratroopers_new(battle_state, battle_actions).battle_step)
	append(&out, &offensive_subs_retreat_new(battle_state, battle_actions).battle_step)
	append(&out, &defensive_subs_retreat_new(battle_state, battle_actions).battle_step)
	append(&out, &offensive_first_strike_new(battle_state, battle_actions).battle_step)
	append(&out, &defensive_first_strike_new(battle_state, battle_actions).battle_step)
	append(&out, &clear_first_strike_casualties_new(battle_state, battle_actions).battle_step)
	append(&out, &offensive_general_new(battle_state, battle_actions).battle_step)
	append(&out, &defensive_general_new(battle_state, battle_actions).battle_step)
	append(&out, &clear_aa_casualties_new(battle_state, battle_actions).battle_step)
	append(&out, &remove_non_combatants_new(battle_state, battle_actions).battle_step)
	append(&out, &mark_no_movement_left_new(battle_state, battle_actions).battle_step)
	append(&out, &remove_first_strike_suicide_new(battle_state, battle_actions).battle_step)
	append(&out, &remove_general_suicide_new(battle_state, battle_actions).battle_step)
	append(&out, &offensive_general_retreat_new(battle_state, battle_actions).battle_step)
	append(&out, &clear_general_casualties_new(battle_state, battle_actions).battle_step)
	append(&out, &remove_unprotected_units_general_new(battle_state, battle_actions).battle_step)
	append(&out, &check_general_battle_end_new(battle_state, battle_actions).battle_step)
	append(&out, &check_stalemate_battle_end_new(battle_state, battle_actions).battle_step)
	return out
}

