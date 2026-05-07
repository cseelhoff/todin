package game

Naval_Bombardment :: struct {
	using battle_step: Battle_Step,
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
}

naval_bombardment_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return naval_bombardment_get_all_step_details(cast(^Naval_Bombardment)self)
}

naval_bombardment_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	naval_bombardment_execute(cast(^Naval_Bombardment)self, stack, bridge)
}

naval_bombardment_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Naval_Bombardment {
	self := new(Naval_Bombardment)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.battle_step.get_all_step_details = naval_bombardment_v_get_all_step_details
	self.battle_step.get_order = naval_bombardment_v_get_order
	self.battle_step.i_executable.execute = naval_bombardment_v_execute
	return self
}

naval_bombardment_v_get_order :: proc(self: ^Battle_Step) -> Battle_Step_Order {
	return naval_bombardment_get_order(cast(^Naval_Bombardment)self)
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
		naval_bombardment_bombardment_dice_roller_apply_stateless,
	)
	builder = fire_round_steps_factory_builder_casualty_selector(
		builder,
		naval_bombardment_bombardment_casualty_selector_apply_stateless,
	)

	factory := fire_round_steps_factory_builder_build(builder)
	return fire_round_steps_factory_create_steps(factory)
}

// Java: public List<StepDetails> getAllStepDetails()
//   return !valid()
//       ? List.of()
//       : getSteps().stream()
//           .flatMap(step -> step.getAllStepDetails().stream())
//           .collect(Collectors.toList());
naval_bombardment_get_all_step_details :: proc(
	self: ^Naval_Bombardment,
) -> [dynamic]^Battle_Step_Step_Details {
	result := make([dynamic]^Battle_Step_Step_Details)
	if !naval_bombardment_valid(self) {
		return result
	}
	steps := naval_bombardment_get_steps(self)
	for step in steps {
		details := naval_bombardment_lambda__get_all_step_details__0(step)
		for d in details {
			append(&result, d)
		}
	}
	return result
}

// Java: public void execute(ExecutionStack stack, IDelegateBridge bridge)
//   if (!valid()) return;
//   Collection<Unit> bombardingUnits = battleState.getBombardingUnits();
//   if (!bombardingUnits.isEmpty()) {
//     Change change = ChangeFactory.markNoMovementChange(bombardingUnits);
//     bridge.addChange(change);
//   }
//   List<BattleStep> steps = getSteps();
//   if (!steps.isEmpty()) {
//     bridge.getSoundChannelBroadcaster().playSoundForAll(
//         SoundPath.CLIP_BATTLE_BOMBARD, battleState.getPlayer(side));
//     Collections.reverse(steps);
//     steps.forEach(stack::push);
//   }
//
// Notes:
//   - SoundPath.CLIP_BATTLE_BOMBARD is the literal string "battle_bombard"
//     (see SoundPath.java); the Odin sound channel takes the bare key.
//   - Battle_Step embeds I_Executable at offset 0 (see battle_step.odin);
//     casting `^Battle_Step` to `^I_Executable` matches the
//     defensive_first_strike_execute / move_performer pattern for
//     stack::push.
naval_bombardment_execute :: proc(
	self: ^Naval_Bombardment,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	if !naval_bombardment_valid(self) {
		return
	}

	bombarding_units := battle_state_get_bombarding_units(self.battle_state)
	if len(bombarding_units) > 0 {
		change := change_factory_mark_no_movement_change_collection(bombarding_units)
		i_delegate_bridge_add_change(bridge, change)
	}

	steps := naval_bombardment_get_steps(self)
	if len(steps) > 0 {
		channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
		headless_sound_channel_play_sound_for_all(
			channel,
			"battle_bombard",
			battle_state_get_player(self.battle_state, .OFFENSE),
		)

		// Collections.reverse: in-place reverse of the dynamic array.
		n := len(steps)
		for i in 0 ..< n / 2 {
			steps[i], steps[n - 1 - i] = steps[n - 1 - i], steps[i]
		}
		// steps.forEach(stack::push)
		for step in steps {
			execution_stack_push_one(stack, cast(^I_Executable)step)
		}
	}
}
