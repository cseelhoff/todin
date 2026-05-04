package game

Offensive_First_Strike :: struct {
	using battle_step:  Battle_Step,
	battle_state:    ^Battle_State,
	battle_actions:  ^Battle_Actions,
	state:           Offensive_First_Strike_State,
	return_fire:     Must_Fight_Battle_Return_Fire,
}

// Java: private State calculateState()
//   if (battleState.filterUnits(ALIVE, side).stream().noneMatch(Matches.unitIsFirstStrike())) {
//     return State.NOT_APPLICABLE;
//   }
//   // ww2v2 rules require subs to always fire in a sub phase
//   if (Properties.getWW2V2(battleState.getGameData().getProperties())) {
//     return State.FIRST_STRIKE;
//   }
//   final boolean canSneakAttack =
//       battleState.filterUnits(ALIVE, side.getOpposite()).stream()
//           .noneMatch(Matches.unitIsDestroyer());
//   if (canSneakAttack) {
//     return State.FIRST_STRIKE;
//   }
//   return State.REGULAR;
//
// `side` is the static OFFENSE constant in the Java class.
offensive_first_strike_calculate_state :: proc(
	self: ^Offensive_First_Strike,
) -> Offensive_First_Strike_State {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)

	offense_alive := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	first_strike_p, first_strike_c := matches_unit_is_first_strike()
	any_first_strike := false
	for u in offense_alive {
		if first_strike_p(first_strike_c, u) {
			any_first_strike = true
			break
		}
	}
	if !any_first_strike {
		return .NOT_APPLICABLE
	}

	game_data := battle_state_get_game_data(self.battle_state)
	if properties_get_ww2_v2(game_data_get_properties(game_data)) {
		return .FIRST_STRIKE
	}

	opposite := battle_state_side_get_opposite(.OFFENSE)
	defense_alive := battle_state_filter_units(self.battle_state, alive_filter, opposite)
	destroyer_p, destroyer_c := matches_unit_is_destroyer()
	can_sneak_attack := true
	for u in defense_alive {
		if destroyer_p(destroyer_c, u) {
			can_sneak_attack = false
			break
		}
	}
	if can_sneak_attack {
		return .FIRST_STRIKE
	}
	return .REGULAR
}

offensive_first_strike_get_order :: proc(self: ^Offensive_First_Strike) -> Battle_Step_Order {
	if self.state == .REGULAR {
		return .FIRST_STRIKE_OFFENSIVE_REGULAR
	}
	return .FIRST_STRIKE_OFFENSIVE
}

offensive_first_strike_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}

// Java: private List<BattleStep> getSteps()
// Source:
//   return FireRoundStepsFactory.builder()
//       .battleState(battleState)
//       .battleActions(battleActions)
//       .firingGroupSplitter(
//           FiringGroupSplitterGeneral.of(
//               side, FiringGroupSplitterGeneral.Type.FIRST_STRIKE, FIRST_STRIKE_UNITS))
//       .side(side)
//       .returnFire(returnFire)
//       .diceRoller(new MainDiceRoller())
//       .casualtySelector(new SelectMainBattleCasualties())
//       .build()
//       .createSteps();
//
// `side` is the static OFFENSE constant in the Java class.
offensive_first_strike_get_steps :: proc(self: ^Offensive_First_Strike) -> [dynamic]^Battle_Step {
	// Java's FiringGroupSplitterGeneral implements Function<BattleState,
	// List<FiringGroup>> and captures (side, type, FIRST_STRIKE_UNITS) on
	// the instance. The Odin Fire_Round_Steps_Factory.firing_group_splitter
	// field is a stateless `proc(^Battle_State) -> [dynamic]^Firing_Group`,
	// so the configuration cannot ride along with the function value here.
	// We still construct the splitter instance for parity with the Java
	// allocation; the forward-referenced `firing_group_splitter_general_apply`
	// (Layer 6, defined later in the package) is what Fire_Round_Steps_Factory
	// will invoke at create-steps time.
	splitter := firing_group_splitter_general_new(
		.OFFENSE,
		.FIRST_STRIKE,
		BATTLE_STEP_FIRST_STRIKE_UNITS,
	)

	side_local: Battle_State_Side = .OFFENSE
	return_fire_local := self.return_fire

	builder := fire_round_steps_factory_builder()
	fire_round_steps_factory_builder_battle_state(builder, self.battle_state)
	fire_round_steps_factory_builder_battle_actions(builder, self.battle_actions)
	fire_round_steps_factory_builder_firing_group_splitter(
		builder,
		firing_group_splitter_general_apply,
		splitter,
	)
	fire_round_steps_factory_builder_side(builder, &side_local)
	fire_round_steps_factory_builder_return_fire(builder, &return_fire_local)
	fire_round_steps_factory_builder_dice_roller(builder, main_dice_roller_apply)
	fire_round_steps_factory_builder_casualty_selector(
		builder,
		select_main_battle_casualties_apply,
	)

	factory := fire_round_steps_factory_builder_build(builder)
	return fire_round_steps_factory_create_steps(factory)
}

// Java: public List<StepDetails> getAllStepDetails()
//   return state == NOT_APPLICABLE
//       ? List.of()
//       : getSteps().stream()
//           .flatMap(step -> step.getAllStepDetails().stream())
//           .collect(Collectors.toList());
offensive_first_strike_get_all_step_details :: proc(self: ^Offensive_First_Strike) -> [dynamic]^Battle_Step_Step_Details {
	result: [dynamic]^Battle_Step_Step_Details
	if self.state == .NOT_APPLICABLE {
		return result
	}
	steps := offensive_first_strike_get_steps(self)
	for step in steps {
		details := offensive_first_strike_lambda__get_all_step_details__0(step)
		for d in details {
			append(&result, d)
		}
	}
	return result
}

// Java: public void execute(ExecutionStack stack, IDelegateBridge bridge)
//   if (state == NOT_APPLICABLE) return;
//   List<BattleStep> steps = getSteps();
//   Collections.reverse(steps);   // steps go in reverse order on the stack
//   steps.forEach(stack::push);
offensive_first_strike_execute :: proc(
	self: ^Offensive_First_Strike,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	if self.state == .NOT_APPLICABLE {
		return
	}
	steps := offensive_first_strike_get_steps(self)
	n := len(steps)
	for i := 0; i < n / 2; i += 1 {
		steps[i], steps[n - 1 - i] = steps[n - 1 - i], steps[i]
	}
	for s in steps {
		execution_stack_push_one(stack, &s.i_executable)
	}
}
