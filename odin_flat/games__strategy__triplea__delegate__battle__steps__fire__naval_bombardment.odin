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
