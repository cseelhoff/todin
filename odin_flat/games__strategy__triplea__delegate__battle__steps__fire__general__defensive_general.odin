package game

Defensive_General :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

defensive_general_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Defensive_General {
	self := new(Defensive_General)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

defensive_general_get_order :: proc(self: ^Defensive_General) -> Battle_Step_Order {
	return .GENERAL_DEFENSIVE
}

defensive_general_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}

// Java: List<StepDetails> getAllStepDetails()
//   return getSteps().stream()
//       .flatMap(step -> step.getAllStepDetails().stream())
//       .collect(Collectors.toList());
defensive_general_get_all_step_details :: proc(
	self: ^Defensive_General,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	steps := defensive_general_get_steps(self)
	for step in steps {
		details := defensive_general_lambda__get_all_step_details__0(step)
		for d in details {
			append(&out, d)
		}
	}
	return out
}

// Java: void execute(ExecutionStack stack, IDelegateBridge bridge)
//   final List<BattleStep> steps = getSteps();
//   // steps go in reverse order on the stack
//   Collections.reverse(steps);
//   steps.forEach(stack::push);
defensive_general_execute :: proc(
	self: ^Defensive_General,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	steps := defensive_general_get_steps(self)
	n := len(steps)
	for i in 0 ..< n / 2 {
		steps[i], steps[n - 1 - i] = steps[n - 1 - i], steps[i]
	}
	// Battle_Step embeds I_Executable at offset 0; cast mirrors the
	// pattern used in defensive_first_strike_execute.
	for step in steps {
		execution_stack_push_one(stack, cast(^I_Executable)step)
	}
}

// Java: private List<BattleStep> DefensiveGeneral.getSteps()
//
//   return FireRoundStepsFactory.builder()
//       .battleState(battleState)
//       .battleActions(battleActions)
//       .firingGroupSplitter(
//           FiringGroupSplitterGeneral.of(side, FiringGroupSplitterGeneral.Type.NORMAL, UNITS))
//       .side(side)
//       .returnFire(ReturnFire.ALL)
//       .diceRoller(new MainDiceRoller())
//       .casualtySelector(new SelectMainBattleCasualties())
//       .build()
//       .createSteps();
//
// `side` here is the static field initialised to DEFENSE in DefensiveGeneral.
// The factory's builder fields take plain proc values whose signatures match
// the Java functional-interface `apply` shapes; we therefore reference the
// per-class `_apply` procs directly. `firing_group_splitter_general_new` is
// still allocated to mirror the Java side-effect of constructing a splitter
// instance even though the proc-value port cannot carry the captured side /
// type / group_name fields (a pre-existing limitation of the factory port —
// the splitter's apply will read those from package-level state when
// implemented at method_layer 6).
defensive_general_get_steps :: proc(self: ^Defensive_General) -> [dynamic]^Battle_Step {
	side_val := Battle_State_Side.DEFENSE
	return_fire_val := Must_Fight_Battle_Return_Fire.ALL

	splitter := firing_group_splitter_general_new(
		side_val,
		Firing_Group_Splitter_General_Type.NORMAL,
		BATTLE_STEP_UNITS,
	)

	dice_roller := main_dice_roller_new()
	_ = dice_roller

	casualty_selector := select_main_battle_casualties_new()
	_ = casualty_selector

	builder := fire_round_steps_factory_builder()
	builder = fire_round_steps_factory_builder_battle_state(builder, self.battle_state)
	builder = fire_round_steps_factory_builder_battle_actions(builder, self.battle_actions)
	builder = fire_round_steps_factory_builder_firing_group_splitter(builder, firing_group_splitter_general_apply_raw, splitter)
	builder = fire_round_steps_factory_builder_side(builder, &side_val)
	builder = fire_round_steps_factory_builder_return_fire(builder, &return_fire_val)
	builder = fire_round_steps_factory_builder_dice_roller(builder, main_dice_roller_apply_stateless)
	builder = fire_round_steps_factory_builder_casualty_selector(builder, select_main_battle_casualties_apply_stateless)

	factory := fire_round_steps_factory_builder_build(builder)
	return fire_round_steps_factory_create_steps(factory)
}
