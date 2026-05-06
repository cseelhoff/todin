package game

Defensive_First_Strike :: struct {
	using battle_step:  Battle_Step,
	battle_state:    ^Battle_State,
	battle_actions:  ^Battle_Actions,
	state:           Defensive_First_Strike_State,
	return_fire:     Must_Fight_Battle_Return_Fire,
}

defensive_first_strike_get_order :: proc(self: ^Defensive_First_Strike) -> Battle_Step_Order {
	if self.state == .REGULAR {
		return .FIRST_STRIKE_DEFENSIVE_REGULAR
	}
	return .FIRST_STRIKE_DEFENSIVE
}

defensive_first_strike_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}

// Java: List<StepDetails> getAllStepDetails()
//   return this.state == State.NOT_APPLICABLE
//       ? List.of()
//       : getSteps().stream()
//           .flatMap(step -> step.getAllStepDetails().stream())
//           .collect(Collectors.toList());
defensive_first_strike_get_all_step_details :: proc(
	self: ^Defensive_First_Strike,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	if self.state == .NOT_APPLICABLE {
		return out
	}
	// Forward ref: defensive_first_strike_get_steps is defined later in
	// the package (mirrors private getSteps() on the Java side).
	steps := defensive_first_strike_get_steps(self)
	for step in steps {
		details := defensive_first_strike_lambda__get_all_step_details__0(step)
		for d in details {
			append(&out, d)
		}
	}
	return out
}

// Java: void execute(ExecutionStack stack, IDelegateBridge bridge)
//   if (this.state == State.NOT_APPLICABLE) { return; }
//   final List<BattleStep> steps = getSteps();
//   // steps go in reverse order on the stack
//   Collections.reverse(steps);
//   steps.forEach(stack::push);
defensive_first_strike_execute :: proc(
	self: ^Defensive_First_Strike,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	if self.state == .NOT_APPLICABLE {
		return
	}
	steps := defensive_first_strike_get_steps(self)
	n := len(steps)
	// Collections.reverse: in-place reverse of the dynamic array.
	for i in 0 ..< n / 2 {
		steps[i], steps[n - 1 - i] = steps[n - 1 - i], steps[i]
	}
	// steps.forEach(stack::push): Battle_Step embeds I_Executable at
	// offset 0, matching the move_performer.odin pattern.
	for step in steps {
		execution_stack_push_one(stack, cast(^I_Executable)step)
	}
}

// Java: private State calculateState()
//   if (battleState.filterUnits(ALIVE, side).stream()
//           .noneMatch(Matches.unitIsFirstStrikeOnDefense(
//               battleState.getGameData().getProperties()))) {
//     return State.NOT_APPLICABLE;
//   }
//   if (Properties.getWW2V2(battleState.getGameData().getProperties())) {
//     return State.FIRST_STRIKE;
//   }
//   final boolean canSneakAttack =
//       battleState.filterUnits(ALIVE, side.getOpposite()).stream()
//               .noneMatch(Matches.unitIsDestroyer())
//           && Properties.getDefendingSubsSneakAttack(
//               battleState.getGameData().getProperties());
//   if (canSneakAttack) { return State.FIRST_STRIKE; }
//   return State.REGULAR;
defensive_first_strike_calculate_state :: proc(
	self: ^Defensive_First_Strike,
) -> Defensive_First_Strike_State {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)

	game_data := battle_state_get_game_data(self.battle_state)
	properties := game_data_get_properties(game_data)

	defense_alive := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
	first_strike_p, first_strike_c := matches_unit_is_first_strike_on_defense(properties)
	any_first_strike := false
	for u in defense_alive {
		if first_strike_p(first_strike_c, u) {
			any_first_strike = true
			break
		}
	}
	if !any_first_strike {
		return .NOT_APPLICABLE
	}

	// ww2v2 rules require subs to always fire in a sub phase
	if properties_get_ww2_v2(properties) {
		return .FIRST_STRIKE
	}

	opposite := battle_state_side_get_opposite(.DEFENSE)
	offense_alive := battle_state_filter_units(self.battle_state, alive_filter, opposite)
	destroyer_p, destroyer_c := matches_unit_is_destroyer()
	none_destroyer := true
	for u in offense_alive {
		if destroyer_p(destroyer_c, u) {
			none_destroyer = false
			break
		}
	}
	can_sneak_attack := none_destroyer && properties_get_defending_subs_sneak_attack(properties)
	if can_sneak_attack {
		return .FIRST_STRIKE
	}
	return .REGULAR
}

// Java: public DefensiveFirstStrike(BattleState battleState, BattleActions battleActions)
//   this.battleState = battleState;
//   this.battleActions = battleActions;
//   this.state = calculateState();
// (returnFire defaults to ReturnFire.ALL per the field initializer.)
defensive_first_strike_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return defensive_first_strike_get_all_step_details(cast(^Defensive_First_Strike)self)
}

defensive_first_strike_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	defensive_first_strike_execute(cast(^Defensive_First_Strike)self, stack, bridge)
}

defensive_first_strike_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Defensive_First_Strike {
	self := new(Defensive_First_Strike)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.return_fire = .ALL
	self.state = defensive_first_strike_calculate_state(self)
	self.battle_step.get_all_step_details = defensive_first_strike_v_get_all_step_details
	self.battle_step.i_executable.execute = defensive_first_strike_v_execute
	return self
}

// Java: private List<BattleStep> getSteps()
//   Mirrors offensive_first_strike_get_steps; the only difference is
//   `side = DEFENSE` and the splitter receives DEFENSE as its first
//   constructor argument.
defensive_first_strike_get_steps :: proc(self: ^Defensive_First_Strike) -> [dynamic]^Battle_Step {
	splitter := firing_group_splitter_general_new(
		.DEFENSE,
		.FIRST_STRIKE,
		BATTLE_STEP_FIRST_STRIKE_UNITS,
	)

	side_local: Battle_State_Side = .DEFENSE
	return_fire_local := self.return_fire

	builder := fire_round_steps_factory_builder()
	fire_round_steps_factory_builder_battle_state(builder, self.battle_state)
	fire_round_steps_factory_builder_battle_actions(builder, self.battle_actions)
	fire_round_steps_factory_builder_firing_group_splitter(
		builder,
		firing_group_splitter_general_apply_raw,
		splitter,
	)
	fire_round_steps_factory_builder_side(builder, &side_local)
	fire_round_steps_factory_builder_return_fire(builder, &return_fire_local)
	fire_round_steps_factory_builder_dice_roller(builder, main_dice_roller_apply_stateless)
	fire_round_steps_factory_builder_casualty_selector(
		builder,
		select_main_battle_casualties_apply_stateless,
	)

	factory := fire_round_steps_factory_builder_build(builder)
	return fire_round_steps_factory_create_steps(factory)
}
