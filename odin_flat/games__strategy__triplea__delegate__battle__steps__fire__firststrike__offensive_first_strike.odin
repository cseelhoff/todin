package game

Offensive_First_Strike :: struct {
	using battle_step:  Battle_Step,
	battle_state:    ^Battle_State,
	battle_actions:  ^Battle_Actions,
	state:           Offensive_First_Strike_State,
	return_fire:     Must_Fight_Battle_Return_Fire,
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
