package game

Naval_Bombardment :: struct {
	using battle_step: Battle_Step,
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
}

naval_bombardment_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Naval_Bombardment {
	self := new(Naval_Bombardment)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

naval_bombardment_get_order :: proc(self: ^Naval_Bombardment) -> Battle_Step_Order {
	return .NAVAL_BOMBARDMENT
}

naval_bombardment_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}

naval_bombardment_valid :: proc(self: ^Naval_Bombardment) -> bool {
	return battle_status_is_first_round(battle_state_get_status(self.battle_state)) &&
		len(battle_state_get_bombarding_units(self.battle_state)) > 0 &&
		!territory_is_water(battle_state_get_battle_site(self.battle_state))
}

// Java: private MustFightBattle.ReturnFire calculateReturnFire()
// If step strings exist and do not contain REMOVE_BOMBARDMENT_CASUALTIES
// (i.e. an old save predating that step), honor the
// "Naval Bombard Casualties Return Fire" property: ALL when true, NONE when
// false. Otherwise (battle just started or new-style save) return ALL.
naval_bombardment_calculate_return_fire :: proc(
	self: ^Naval_Bombardment,
) -> Must_Fight_Battle_Return_Fire {
	step_strings := battle_state_get_step_strings(self.battle_state)
	if len(step_strings) > 0 {
		contains_remove := false
		for s in step_strings {
			if s == BATTLE_STEP_REMOVE_BOMBARDMENT_CASUALTIES {
				contains_remove = true
				break
			}
		}
		if !contains_remove {
			if properties_get_naval_bombard_casualties_return_fire(
				game_data_get_properties(battle_state_get_game_data(self.battle_state)),
			) {
				return .ALL
			}
			return .NONE
		}
	}
	return .ALL
}

// Java: private List<BattleStep> getSteps()
//   return FireRoundStepsFactory.builder()
//       .battleState(battleState)
//       .battleActions(battleActions)
//       .firingGroupSplitter(FiringGroupSplitterBombard.of())
//       .side(side)                          // OFFENSE
//       .returnFire(calculateReturnFire())
//       .diceRoller(new BombardmentDiceRoller())
//       .casualtySelector(new BombardmentCasualtySelector())
//       .build()
//       .createSteps();
//
// Odin's Fire_Round_Steps_Factory firing-group-splitter slot is a
// `proc(rawptr, ^Battle_State) -> [dynamic]^Firing_Group`, while the
// underlying `firing_group_splitter_bombard_apply` proc is typed
// `proc(^Firing_Group_Splitter_Bombard, ^Battle_State) -> ...`. The
// two proc types are not assignment-compatible in Odin even though the
// receiver is a pointer, so we route through a tiny rawptr→typed
// adapter that carries the splitter instance as ctx.
//
// `naval_bombardment_bombardment_dice_roller_apply` and
// `naval_bombardment_bombardment_casualty_selector_apply` are stateless
// (the Java inner classes have no instance fields), so we hand them to
// the builder as bare procs; they are forward references resolved at
// the package level when those inner-class methods are ported.
naval_bombardment_lambda__get_steps__firing_group_splitter :: proc(
	self_raw: rawptr,
	state: ^Battle_State,
) -> [dynamic]^Firing_Group {
	splitter := cast(^Firing_Group_Splitter_Bombard)self_raw
	return firing_group_splitter_bombard_apply(splitter, state)
}

naval_bombardment_get_steps :: proc(self: ^Naval_Bombardment) -> [dynamic]^Battle_Step {
	splitter := firing_group_splitter_bombard_of()

	dice_roller := naval_bombardment_bombardment_dice_roller_new()
	_ = dice_roller

	casualty_selector := naval_bombardment_bombardment_casualty_selector_new()
	_ = casualty_selector

	side_local: Battle_State_Side = .OFFENSE
	return_fire_local := naval_bombardment_calculate_return_fire(self)

	builder := fire_round_steps_factory_builder()
	builder = fire_round_steps_factory_builder_battle_state(builder, self.battle_state)
	builder = fire_round_steps_factory_builder_battle_actions(builder, self.battle_actions)
	builder = fire_round_steps_factory_builder_firing_group_splitter(
		builder,
		naval_bombardment_lambda__get_steps__firing_group_splitter,
		splitter,
	)
	builder = fire_round_steps_factory_builder_side(builder, &side_local)
	builder = fire_round_steps_factory_builder_return_fire(builder, &return_fire_local)
	builder = fire_round_steps_factory_builder_dice_roller(
		builder,
		naval_bombardment_bombardment_dice_roller_apply,
	)
	builder = fire_round_steps_factory_builder_casualty_selector(
		builder,
		naval_bombardment_bombardment_casualty_selector_apply,
	)

	factory := fire_round_steps_factory_builder_build(builder)
	return fire_round_steps_factory_create_steps(factory)
}
