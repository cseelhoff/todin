package game

import "core:fmt"

Roll_Dice_Step :: struct {
	using battle_step: Battle_Step,
	battle_state:     ^Battle_State,
	side:             Battle_State_Side,
	firing_group:     ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	roll_dice:        proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
}

roll_dice_step_new :: proc(
	battle_state: ^Battle_State,
	side: Battle_State_Side,
	firing_group: ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	roll_dice: proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
) -> ^Roll_Dice_Step {
	self := new(Roll_Dice_Step)
	self.battle_state = battle_state
	self.side = side
	self.firing_group = firing_group
	self.fire_round_state = fire_round_state
	self.roll_dice = roll_dice
	return self
}

roll_dice_step_get_battle_state :: proc(self: ^Roll_Dice_Step) -> ^Battle_State {
	return self.battle_state
}

roll_dice_step_get_firing_group :: proc(self: ^Roll_Dice_Step) -> ^Firing_Group {
	return self.firing_group
}

roll_dice_step_get_side :: proc(self: ^Roll_Dice_Step) -> Battle_State_Side {
	return self.side
}

// Java: public List<StepDetails> getAllStepDetails()
//   return List.of(new StepDetails(getName(), this));
roll_dice_step_get_all_step_details :: proc(self: ^Roll_Dice_Step) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	append(&out, battle_step_step_details_new(roll_dice_step_get_name(self), &self.battle_step))
	return out
}

// Java: private String getName()
//   battleState.getPlayer(side).getName()
//     + (firingGroup.getDisplayName().equals(UNITS) ? "" : " " + firingGroup.getDisplayName())
//     + FIRE_SUFFIX
roll_dice_step_get_name :: proc(self: ^Roll_Dice_Step) -> string {
	player := battle_state_get_player(self.battle_state, self.side)
	display_name := firing_group_get_display_name(self.firing_group)
	middle: string
	if display_name == BATTLE_STEP_UNITS {
		middle = ""
	} else {
		middle = fmt.aprintf(" %s", display_name)
	}
	return fmt.aprintf("%s%s%s", player.named.base.name, middle, BATTLE_STEP_FIRE_SUFFIX)
}

// Java: public void execute(ExecutionStack stack, IDelegateBridge bridge)
//   firingGroup.retainAliveTargets(battleState.filterUnits(ALIVE, side.getOpposite()));
//   final DiceRoll dice = rollDice.apply(bridge, this);
//   fireRoundState.setDice(dice);
roll_dice_step_execute :: proc(
	self: ^Roll_Dice_Step,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	opp := battle_state_side_get_opposite(self.side)
	alive_targets := battle_state_filter_units(self.battle_state, alive_filter, opp)
	firing_group_retain_alive_targets(self.firing_group, alive_targets)

	dice := self.roll_dice(bridge, self)
	fire_round_state_set_dice(self.fire_round_state, dice)
}
