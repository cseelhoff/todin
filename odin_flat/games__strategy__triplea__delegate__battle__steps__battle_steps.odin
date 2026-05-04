package game

import "core:slice"

Battle_Steps :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

battle_steps_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Battle_Steps {
	self := new(Battle_Steps)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

battle_steps_builder :: proc() -> ^Battle_Steps_Battle_Steps_Builder {
	return battle_steps_battle_steps_builder_new()
}

// Per-step record carrying both the sort key (Java Comparator.comparing
// (BattleStep::getOrder)) and the flat-mapped step details (Java
// step.getAllStepDetails().stream()). Building the entry list with
// concrete subtypes — rather than going through `battle_step_get_all`
// which erases to `^Battle_Step` — lets us call each subtype's
// `_get_order` and `_get_all_step_details` proc directly without a
// runtime virtual dispatcher.
Battle_Steps_Step_Entry :: struct {
	order:   Battle_Step_Order,
	details: [dynamic]^Battle_Step_Step_Details,
}

// `slice.sort_by` takes a non-capturing `proc(a, b) -> bool` (less-than
// predicate). The Java side uses `Comparator.comparing(BattleStep::
// getOrder)`, which orders enum constants by their declaration index;
// Odin enum values inherit that same ordinal so casting to `int` yields
// the same comparison.
battle_steps_get_entry_less :: proc(a, b: Battle_Steps_Step_Entry) -> bool {
	return int(a.order) < int(b.order)
}

// games.strategy.triplea.delegate.battle.steps.BattleSteps#get()
//
// Java:
//   return BattleStep.getAll(battleState, battleActions).stream()
//       .sorted(Comparator.comparing(BattleStep::getOrder))
//       .flatMap(step -> step.getAllStepDetails().stream())
//       .collect(Collectors.toList());
//
// `BattleStep::getOrder` and `BattleStep#getAllStepDetails` are
// virtual interface methods. Odin's `^Battle_Step` carries no type
// tag, so we cannot dispatch from a `[dynamic]^Battle_Step`
// produced by `battle_step_get_all`; instead we mirror the Java
// `BattleStep.getAll(...)` list inline using each concrete subtype
// and call its specific `_get_order` / `_get_all_step_details`
// proc directly. The 24-element ordered list mirrors
// `BattleStep#getAll` in the Java source.
//
// Three subtypes lack a stand-alone `_get_all_step_details`:
//   * `Offensive_Aa_Fire` and `Defensive_Aa_Fire` inherit the
//     implementation from their parent
//     `Aa_Fire_And_Casualty_Step`; we call
//     `aa_fire_and_casualty_step_get_all_step_details` on the
//     embedded base.
//   * `Offensive_General_Retreat#getAllStepDetails` is not yet
//     ported as its own proc. Its Java body is a one-liner —
//     `isRetreatPossible() ? List.of(new StepDetails(getName(),
//     this)) : List.of()` — so we inline it here using the
//     existing `offensive_general_retreat_is_retreat_possible`
//     and `offensive_general_retreat_get_name` procs.
battle_steps_get :: proc(self: ^Battle_Steps) -> [dynamic]^Battle_Step_Step_Details {
	entries := make([dynamic]Battle_Steps_Step_Entry, 0, 24)

	{
		s := offensive_aa_fire_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = offensive_aa_fire_get_order(s),
				details = aa_fire_and_casualty_step_get_all_step_details(
					&s.aa_fire_and_casualty_step,
				),
			},
		)
	}
	{
		s := defensive_aa_fire_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = defensive_aa_fire_get_order(s),
				details = aa_fire_and_casualty_step_get_all_step_details(
					&s.aa_fire_and_casualty_step,
				),
			},
		)
	}
	{
		s := submerge_subs_vs_only_air_step_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = submerge_subs_vs_only_air_step_get_order(s),
				details = submerge_subs_vs_only_air_step_get_all_step_details(s),
			},
		)
	}
	{
		// Java BattleStep#getAll constructs `new RemoveUnprotectedUnits(...)`
		// at this position; we mirror Java exactly.
		s := remove_unprotected_units_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = remove_unprotected_units_get_order(s),
				details = remove_unprotected_units_get_all_step_details(s),
			},
		)
	}
	{
		s := naval_bombardment_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = naval_bombardment_get_order(s),
				details = naval_bombardment_get_all_step_details(s),
			},
		)
	}
	{
		s := clear_bombardment_casualties_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = clear_bombardment_casualties_get_order(s),
				details = clear_bombardment_casualties_get_all_step_details(s),
			},
		)
	}
	{
		s := land_paratroopers_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = land_paratroopers_get_order(s),
				details = land_paratroopers_get_all_step_details(s),
			},
		)
	}
	{
		s := offensive_subs_retreat_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = offensive_subs_retreat_get_order(s),
				details = offensive_subs_retreat_get_all_step_details(s),
			},
		)
	}
	{
		s := defensive_subs_retreat_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = defensive_subs_retreat_get_order(s),
				details = defensive_subs_retreat_get_all_step_details(s),
			},
		)
	}
	{
		s := offensive_first_strike_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = offensive_first_strike_get_order(s),
				details = offensive_first_strike_get_all_step_details(s),
			},
		)
	}
	{
		s := defensive_first_strike_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = defensive_first_strike_get_order(s),
				details = defensive_first_strike_get_all_step_details(s),
			},
		)
	}
	{
		s := clear_first_strike_casualties_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = clear_first_strike_casualties_get_order(s),
				details = clear_first_strike_casualties_get_all_step_details(s),
			},
		)
	}
	{
		s := offensive_general_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = offensive_general_get_order(s),
				details = offensive_general_get_all_step_details(s),
			},
		)
	}
	{
		s := defensive_general_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = defensive_general_get_order(s),
				details = defensive_general_get_all_step_details(s),
			},
		)
	}
	{
		s := clear_aa_casualties_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = clear_aa_casualties_get_order(s),
				details = clear_aa_casualties_get_all_step_details(s),
			},
		)
	}
	{
		s := remove_non_combatants_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = remove_non_combatants_get_order(s),
				details = remove_non_combatants_get_all_step_details(s),
			},
		)
	}
	{
		s := mark_no_movement_left_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = mark_no_movement_left_get_order(s),
				details = mark_no_movement_left_get_all_step_details(s),
			},
		)
	}
	{
		s := remove_first_strike_suicide_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = remove_first_strike_suicide_get_order(s),
				details = remove_first_strike_suicide_get_all_step_details(s),
			},
		)
	}
	{
		s := remove_general_suicide_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = remove_general_suicide_get_order(s),
				details = remove_general_suicide_get_all_step_details(s),
			},
		)
	}
	{
		// Inline of `OffensiveGeneralRetreat#getAllStepDetails`:
		//   isRetreatPossible() ? List.of(new StepDetails(getName(), this)) : List.of()
		s := offensive_general_retreat_new(self.battle_state, self.battle_actions)
		details := make([dynamic]^Battle_Step_Step_Details)
		if offensive_general_retreat_is_retreat_possible(s) {
			append(
				&details,
				battle_step_step_details_new(
					offensive_general_retreat_get_name(s),
					&s.battle_step,
				),
			)
		}
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = offensive_general_retreat_get_order(s),
				details = details,
			},
		)
	}
	{
		s := clear_general_casualties_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = clear_general_casualties_get_order(s),
				details = clear_general_casualties_get_all_step_details(s),
			},
		)
	}
	{
		s := remove_unprotected_units_general_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = remove_unprotected_units_general_get_order(s),
				details = remove_unprotected_units_general_get_all_step_details(s),
			},
		)
	}
	{
		s := check_general_battle_end_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = check_general_battle_end_get_order(s),
				details = check_general_battle_end_get_all_step_details(s),
			},
		)
	}
	{
		s := check_stalemate_battle_end_new(self.battle_state, self.battle_actions)
		append(
			&entries,
			Battle_Steps_Step_Entry{
				order   = check_stalemate_battle_end_get_order(s),
				details = check_stalemate_battle_end_get_all_step_details(s),
			},
		)
	}

	slice.sort_by(entries[:], battle_steps_get_entry_less)

	out := make([dynamic]^Battle_Step_Step_Details)
	for e in entries {
		for d in e.details {
			append(&out, d)
		}
	}
	return out
}
