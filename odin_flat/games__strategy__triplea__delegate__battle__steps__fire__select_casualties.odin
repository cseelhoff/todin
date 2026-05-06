package game

import "core:fmt"

Select_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:     ^Battle_State,
	side:             Battle_State_Side,
	firing_group:     ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	select_casualties: proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
}

select_casualties_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	select_casualties_execute(cast(^Select_Casualties)self, stack, bridge)
}

select_casualties_new :: proc(
	battle_state: ^Battle_State,
	side: Battle_State_Side,
	firing_group: ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	select_casualties: proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
) -> ^Select_Casualties {
	self := new(Select_Casualties)
	self.battle_state = battle_state
	self.side = side
	self.firing_group = firing_group
	self.fire_round_state = fire_round_state
	self.select_casualties = select_casualties
	self.battle_step.i_executable.execute = select_casualties_v_execute
	return self
}

select_casualties_get_battle_state :: proc(self: ^Select_Casualties) -> ^Battle_State {
	return self.battle_state
}

select_casualties_get_side :: proc(self: ^Select_Casualties) -> Battle_State_Side {
	return self.side
}

select_casualties_get_firing_group :: proc(self: ^Select_Casualties) -> ^Firing_Group {
	return self.firing_group
}

select_casualties_get_fire_round_state :: proc(self: ^Select_Casualties) -> ^Fire_Round_State {
	return self.fire_round_state
}

// Java: private String getName()
//   return battleState.getPlayer(side.getOpposite()).getName()
//     + SELECT_PREFIX
//     + (firingGroup.getDisplayName().equals(UNITS)
//         ? CASUALTIES_WITHOUT_SPACE_SUFFIX
//         : firingGroup.getDisplayName() + CASUALTIES_SUFFIX)
select_casualties_get_name :: proc(self: ^Select_Casualties) -> string {
	opp := battle_state_side_get_opposite(self.side)
	player := battle_state_get_player(self.battle_state, opp)
	display_name := firing_group_get_display_name(self.firing_group)
	suffix: string
	if display_name == BATTLE_STEP_UNITS {
		suffix = BATTLE_STEP_CASUALTIES_WITHOUT_SPACE_SUFFIX
	} else {
		suffix = fmt.aprintf("%s%s", display_name, BATTLE_STEP_CASUALTIES_SUFFIX)
	}
	return fmt.aprintf("%s%s%s", player.named.base.name, BATTLE_STEP_SELECT_PREFIX, suffix)
}

// Java: SelectCasualties#getAllStepDetails
//   return List.of(new StepDetails(getName(), this));
// Note: Select_Casualties does not embed Battle_Step in this port; the step
// pointer field is passed as nil (consumers identify the step via name).
select_casualties_get_all_step_details :: proc(self: ^Select_Casualties) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	append(&out, battle_step_step_details_new(select_casualties_get_name(self), nil))
	return out
}

// Java: public void execute(ExecutionStack stack, IDelegateBridge bridge)
//   final DiceRoll diceRoll = fireRoundState.getDice();
//   final String stepName = MarkCasualties.getPossibleOldNameForNotifyingBattleDisplay(
//       battleState, firingGroup, side, getName());
//   if (ClientSetting.useWebsocketNetwork.getValue().orElse(false)) {
//     bridge.sendMessage(new IDisplay.NotifyDiceMessage(diceRoll, stepName, diceRoll.getPlayerName()));
//   } else {
//     bridge.getDisplayChannelBroadcaster().notifyDice(diceRoll, stepName);
//   }
//   final CasualtyDetails details = selectCasualties.apply(bridge, this);
//   fireRoundState.setCasualties(details);
//   BattleDelegate.markDamaged(details.getDamaged(), bridge, battleState.getBattleSite());
//
// The websocket branch is dormant for snapshot runs (the setting defaults
// to false); we always take the broadcaster path, mirroring the convention
// used in evader_retreat.odin and remove_non_combatants.odin.
select_casualties_execute :: proc(
	self: ^Select_Casualties,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	dice_roll := fire_round_state_get_dice(self.fire_round_state)
	step_name := mark_casualties_get_possible_old_name_for_notifying_battle_display(
		self.battle_state,
		self.firing_group,
		self.side,
		select_casualties_get_name(self),
	)
	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_notify_dice(display, dice_roll, step_name)

	details := self.select_casualties(bridge, self)
	fire_round_state_set_casualties(self.fire_round_state, details)
	battle_delegate_mark_damaged(
		casualty_list_get_damaged(&details.casualty_list),
		bridge,
		battle_state_get_battle_site(self.battle_state),
	)
}

