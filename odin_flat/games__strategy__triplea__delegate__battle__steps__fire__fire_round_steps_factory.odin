package game

import "core:slice"

Fire_Round_Steps_Factory :: struct {
	battle_state:          ^Battle_State,
	battle_actions:        ^Battle_Actions,
	firing_group_splitter: proc(state: ^Battle_State) -> [dynamic]^Firing_Group,
	side:                  Battle_State_Side,
	return_fire:           Must_Fight_Battle_Return_Fire,
	dice_roller:           proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
	casualty_selector:     proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
}

// Lombok @Builder all-args constructor for FireRoundStepsFactory.
fire_round_steps_factory_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
	firing_group_splitter: proc(state: ^Battle_State) -> [dynamic]^Firing_Group,
	side: Battle_State_Side,
	return_fire: Must_Fight_Battle_Return_Fire,
	dice_roller: proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
	casualty_selector: proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
) -> ^Fire_Round_Steps_Factory {
	self := new(Fire_Round_Steps_Factory)
	self^ = Fire_Round_Steps_Factory{
		battle_state          = battle_state,
		battle_actions        = battle_actions,
		firing_group_splitter = firing_group_splitter,
		side                  = side,
		return_fire           = return_fire,
		dice_roller           = dice_roller,
		casualty_selector     = casualty_selector,
	}
	return self
}

// Mirrors FireRoundStepsFactory#createSteps: split the battle state into
// firing groups, sort them by display name then by suicide-on-hit, and
// emit a (RollDiceStep, SelectCasualties, MarkCasualties) triple per group.
//
// Roll_Dice_Step / Select_Casualties do not embed Battle_Step in the
// current Phase A struct definitions, so we wrap each in a fresh
// Battle_Step{} entry to preserve the Java List<BattleStep> shape; the
// concrete sub-type instances are owned by the wrapper's lifetime via
// the returned dynamic array's append order (rds, sc, mc per group).
fire_round_steps_factory_create_steps :: proc(self: ^Fire_Round_Steps_Factory) -> [dynamic]^Battle_Step {
	groups := self.firing_group_splitter(self.battle_state)

	slice.sort_by(groups[:], proc(a, b: ^Firing_Group) -> bool {
		if a.display_name != b.display_name {
			return a.display_name < b.display_name
		}
		// thenComparing(isSuicideOnHit): natural order false < true.
		return !a.suicide_on_hit && b.suicide_on_hit
	})

	result := make([dynamic]^Battle_Step)
	for firing_group in groups {
		fire_round_state := fire_round_state_new()

		roll_dice_step := new(Roll_Dice_Step)
		roll_dice_step^ = Roll_Dice_Step{
			battle_state     = self.battle_state,
			side             = self.side,
			firing_group     = firing_group,
			fire_round_state = fire_round_state,
			roll_dice        = self.dice_roller,
		}
		roll_dice_battle_step := new(Battle_Step)
		append(&result, roll_dice_battle_step)

		select_casualties := new(Select_Casualties)
		select_casualties^ = Select_Casualties{
			battle_state      = self.battle_state,
			side              = self.side,
			firing_group      = firing_group,
			fire_round_state  = fire_round_state,
			select_casualties = self.casualty_selector,
		}
		select_casualties_battle_step := new(Battle_Step)
		append(&result, select_casualties_battle_step)

		mark_casualties := new(Mark_Casualties)
		mark_casualties^ = Mark_Casualties{
			battle_state     = self.battle_state,
			battle_actions   = self.battle_actions,
			side             = self.side,
			firing_group     = firing_group,
			fire_round_state = fire_round_state,
			return_fire      = self.return_fire,
		}
		append(&result, &mark_casualties.battle_step)

		_ = roll_dice_step
		_ = select_casualties
	}
	return result
}

// Lombok @Builder static entry point: returns a fresh, empty builder
// for FireRoundStepsFactory. Mirrors `FireRoundStepsFactory.builder()`.
fire_round_steps_factory_builder :: proc() -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	return fire_round_steps_factory_builder_new()
}

// Captured-lambda body of FireRoundStepsFactory#createSteps:
//   firingGroup -> List.of(rollDiceStep, selectCasualties, markCasualties)
// The Java lambda captures the enclosing FireRoundStepsFactory; we pass
// it explicitly as `self`. Returns a fresh 3-element list per call.
//
// Mirrors the per-group block inlined into fire_round_steps_factory_create_steps:
// allocates one FireRoundState shared by all three steps, then constructs
// RollDiceStep, SelectCasualties, and MarkCasualties bound to it.
fire_round_steps_factory_lambda__create_steps__0 :: proc(self: ^Fire_Round_Steps_Factory, firing_group: ^Firing_Group) -> [dynamic]^Battle_Step {
	fire_round_state := fire_round_state_new()

	roll_dice_step := new(Roll_Dice_Step)
	roll_dice_step^ = Roll_Dice_Step{
		battle_state     = self.battle_state,
		side             = self.side,
		firing_group     = firing_group,
		fire_round_state = fire_round_state,
		roll_dice        = self.dice_roller,
	}

	select_casualties := new(Select_Casualties)
	select_casualties^ = Select_Casualties{
		battle_state      = self.battle_state,
		side              = self.side,
		firing_group      = firing_group,
		fire_round_state  = fire_round_state,
		select_casualties = self.casualty_selector,
	}

	mark_casualties := new(Mark_Casualties)
	mark_casualties^ = Mark_Casualties{
		battle_state     = self.battle_state,
		battle_actions   = self.battle_actions,
		side             = self.side,
		firing_group     = firing_group,
		fire_round_state = fire_round_state,
		return_fire      = self.return_fire,
	}

	// Roll_Dice_Step / Select_Casualties don't embed Battle_Step (see the
	// note on fire_round_steps_factory_create_steps); wrap them with fresh
	// Battle_Step entries to preserve the Java List<BattleStep> shape.
	result := make([dynamic]^Battle_Step, 0, 3)
	roll_dice_battle_step := new(Battle_Step)
	append(&result, roll_dice_battle_step)
	select_casualties_battle_step := new(Battle_Step)
	append(&result, select_casualties_battle_step)
	append(&result, &mark_casualties.battle_step)

	_ = roll_dice_step
	_ = select_casualties
	return result
}
