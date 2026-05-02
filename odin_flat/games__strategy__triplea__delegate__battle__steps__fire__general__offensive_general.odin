package game

Offensive_General :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

offensive_general_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Offensive_General {
	self := new(Offensive_General)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

offensive_general_get_order :: proc(self: ^Offensive_General) -> Battle_Step_Order {
	return .GENERAL_OFFENSIVE
}

offensive_general_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}

// Java: private List<BattleStep> OffensiveGeneral.getSteps()
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
// `side` here is the static field initialised to OFFENSE in OffensiveGeneral.
// Mirrors defensive_general_get_steps; see notes there for the rationale on
// passing the splitter as ctx and the dice_roller / casualty_selector as
// stateless bare procs (forward refs to layers 6/9/14 are resolved at the
// package level).
offensive_general_get_steps :: proc(self: ^Offensive_General) -> [dynamic]^Battle_Step {
	side_val := Battle_State_Side.OFFENSE
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
	builder = fire_round_steps_factory_builder_firing_group_splitter(builder, firing_group_splitter_general_apply, splitter)
	builder = fire_round_steps_factory_builder_side(builder, &side_val)
	builder = fire_round_steps_factory_builder_return_fire(builder, &return_fire_val)
	builder = fire_round_steps_factory_builder_dice_roller(builder, main_dice_roller_apply)
	builder = fire_round_steps_factory_builder_casualty_selector(builder, select_main_battle_casualties_apply)

	factory := fire_round_steps_factory_builder_build(builder)
	return fire_round_steps_factory_create_steps(factory)
}
