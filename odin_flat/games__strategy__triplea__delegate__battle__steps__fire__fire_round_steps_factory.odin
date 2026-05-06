package game

import "core:slice"

Fire_Round_Steps_Factory :: struct {
	battle_state:              ^Battle_State,
	battle_actions:            ^Battle_Actions,
	// Java's FiringGroupSplitter* instances are Function<BattleState, List<FiringGroup>>
	// closures capturing (side, type, group_name); the ctx pointer carries the Java
	// receiver so the layer-6 *_apply procs can read self state.
	firing_group_splitter:     proc(self_raw: rawptr, state: ^Battle_State) -> [dynamic]^Firing_Group,
	firing_group_splitter_ctx: rawptr,
	side:                      Battle_State_Side,
	return_fire:               Must_Fight_Battle_Return_Fire,
	dice_roller:               proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
	casualty_selector:         proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
}

// Lombok @Builder all-args constructor for FireRoundStepsFactory.
fire_round_steps_factory_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
	firing_group_splitter: proc(self_raw: rawptr, state: ^Battle_State) -> [dynamic]^Firing_Group,
	firing_group_splitter_ctx: rawptr,
	side: Battle_State_Side,
	return_fire: Must_Fight_Battle_Return_Fire,
	dice_roller: proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
	casualty_selector: proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
) -> ^Fire_Round_Steps_Factory {
	self := new(Fire_Round_Steps_Factory)
	self^ = Fire_Round_Steps_Factory{
		battle_state              = battle_state,
		battle_actions            = battle_actions,
		firing_group_splitter     = firing_group_splitter,
		firing_group_splitter_ctx = firing_group_splitter_ctx,
		side                      = side,
		return_fire               = return_fire,
		dice_roller               = dice_roller,
		casualty_selector         = casualty_selector,
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
	groups := self.firing_group_splitter(self.firing_group_splitter_ctx, self.battle_state)

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

		roll_dice_step := roll_dice_step_new(
			self.battle_state,
			self.side,
			firing_group,
			fire_round_state,
			self.dice_roller,
		)
		append(&result, &roll_dice_step.battle_step)

		select_casualties := select_casualties_new(
			self.battle_state,
			self.side,
			firing_group,
			fire_round_state,
			self.casualty_selector,
		)
		append(&result, &select_casualties.battle_step)

		mark_casualties := mark_casualties_new(
			self.battle_state,
			self.battle_actions,
			self.side,
			firing_group,
			fire_round_state,
			self.return_fire,
		)
		append(&result, &mark_casualties.battle_step)
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

	roll_dice_step := roll_dice_step_new(
		self.battle_state,
		self.side,
		firing_group,
		fire_round_state,
		self.dice_roller,
	)

	select_casualties := select_casualties_new(
		self.battle_state,
		self.side,
		firing_group,
		fire_round_state,
		self.casualty_selector,
	)

	mark_casualties := mark_casualties_new(
		self.battle_state,
		self.battle_actions,
		self.side,
		firing_group,
		fire_round_state,
		self.return_fire,
	)

	result := make([dynamic]^Battle_Step, 0, 3)
	append(&result, &roll_dice_step.battle_step)
	append(&result, &select_casualties.battle_step)
	append(&result, &mark_casualties.battle_step)

	return result
}
