package game

import "core:fmt"

Select_Casualties :: struct {
	battle_state:     ^Battle_State,
	side:             Battle_State_Side,
	firing_group:     ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	select_casualties: proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
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

