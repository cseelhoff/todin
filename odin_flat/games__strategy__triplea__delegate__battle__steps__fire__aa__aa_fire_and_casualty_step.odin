package game

Aa_Fire_And_Casualty_Step :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	// Java's `abstract Side getSide()` is realized by storing the side
	// chosen by the concrete subclass on construction. Offensive_Aa_Fire
	// and Defensive_Aa_Fire set this in their `_new` constructors so the
	// shared `getSteps()` body can read it without a virtual dispatch.
	side:           Battle_State_Side,
}

aa_fire_and_casualty_step_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Aa_Fire_And_Casualty_Step {
	self := new(Aa_Fire_And_Casualty_Step)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

aa_fire_and_casualty_step_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}

// Mirrors AaFireAndCasualtyStep#getSteps:
//   FireRoundStepsFactory.builder()
//       .battleState(battleState)
//       .battleActions(battleActions)
//       .firingGroupSplitter(FiringGroupSplitterAa.of(getSide()))
//       .side(getSide())
//       .returnFire(MustFightBattle.ReturnFire.ALL)
//       .diceRoller(new AaDiceRoller())
//       .casualtySelector(new SelectAaCasualties())
//       .build()
//       .createSteps();
//
// `firing_group_splitter_aa_apply`, `aa_fire_and_casualty_step_aa_dice_roller_apply`,
// and `aa_fire_and_casualty_step_select_aa_casualties_apply` are forward
// references to procs ported in higher method layers; Odin's package-level
// scope resolves them at compile time once the rest of Phase B lands.
aa_fire_and_casualty_step_get_steps :: proc(self: ^Aa_Fire_And_Casualty_Step) -> [dynamic]^Battle_Step {
	splitter := firing_group_splitter_aa_of(self.side)
	side_val := self.side
	return_fire_val := Must_Fight_Battle_Return_Fire.ALL

	builder := fire_round_steps_factory_builder()
	fire_round_steps_factory_builder_battle_state(builder, self.battle_state)
	fire_round_steps_factory_builder_battle_actions(builder, self.battle_actions)
	fire_round_steps_factory_builder_firing_group_splitter(builder, firing_group_splitter_aa_apply, splitter)
	fire_round_steps_factory_builder_side(builder, &side_val)
	fire_round_steps_factory_builder_return_fire(builder, &return_fire_val)
	fire_round_steps_factory_builder_dice_roller(builder, aa_fire_and_casualty_step_aa_dice_roller_apply)
	fire_round_steps_factory_builder_casualty_selector(builder, aa_fire_and_casualty_step_select_aa_casualties_apply)
	factory := fire_round_steps_factory_builder_build(builder)
	return fire_round_steps_factory_create_steps(factory)
}
