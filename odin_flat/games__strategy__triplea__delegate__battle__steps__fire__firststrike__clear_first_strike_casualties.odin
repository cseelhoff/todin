package game

Clear_First_Strike_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	offense_state:  Clear_First_Strike_Casualties_State,
	defense_state:  Clear_First_Strike_Casualties_State,
}

clear_first_strike_casualties_get_order :: proc(self: ^Clear_First_Strike_Casualties) -> Battle_Step_Order {
	return .FIRST_STRIKE_REMOVE_CASUALTIES
}

clear_first_strike_casualties_offense_has_sneak_attack :: proc(self: ^Clear_First_Strike_Casualties) -> bool {
	return self.offense_state == .SNEAK_ATTACK
}

clear_first_strike_casualties_defense_has_sneak_attack :: proc(self: ^Clear_First_Strike_Casualties) -> bool {
	return self.defense_state == .SNEAK_ATTACK
}

// Java: ClearFirstStrikeCasualties#calculateOffenseState
//   if (battleState.filterUnits(ALIVE, OFFENSE).stream().anyMatch(Matches.unitIsFirstStrike())) {
//     final boolean canSneakAttack =
//         battleState.filterUnits(ALIVE, DEFENSE).stream().noneMatch(Matches.unitIsDestroyer());
//     if (canSneakAttack) return State.SNEAK_ATTACK;
//   }
//   return State.NO_SNEAK_ATTACK;
clear_first_strike_casualties_calculate_offense_state :: proc(
	self: ^Clear_First_Strike_Casualties,
) -> Clear_First_Strike_Casualties_State {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	offense_units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	fs_p, fs_c := matches_unit_is_first_strike()
	any_first_strike := false
	for u in offense_units {
		if fs_p(fs_c, u) {
			any_first_strike = true
			break
		}
	}
	if any_first_strike {
		alive_filter2 := battle_state_unit_battle_filter_new(.Alive)
		defense_units := battle_state_filter_units(self.battle_state, alive_filter2, .DEFENSE)
		destroyer_p, destroyer_c := matches_unit_is_destroyer()
		can_sneak_attack := true
		for u in defense_units {
			if destroyer_p(destroyer_c, u) {
				can_sneak_attack = false
				break
			}
		}
		if can_sneak_attack {
			return .SNEAK_ATTACK
		}
	}
	return .NO_SNEAK_ATTACK
}

// Java: ClearFirstStrikeCasualties#getAllStepDetails
//   if (offenseHasSneakAttack() || defenseHasSneakAttack()) {
//     return List.of(new StepDetails(REMOVE_SNEAK_ATTACK_CASUALTIES, this));
//   }
//   return List.of();
clear_first_strike_casualties_get_all_step_details :: proc(
	self: ^Clear_First_Strike_Casualties,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	if clear_first_strike_casualties_offense_has_sneak_attack(self) ||
	   clear_first_strike_casualties_defense_has_sneak_attack(self) {
		append(&out, battle_step_step_details_new(BATTLE_STEP_REMOVE_SNEAK_ATTACK_CASUALTIES, &self.battle_step))
	}
	return out
}

// Java: ClearFirstStrikeCasualties#getSidesToClear
//   if (Properties.getWW2V2(battleState.getGameData().getProperties())) {
//     if (offenseState == SNEAK_ATTACK && defenseState != SNEAK_ATTACK) return EnumSet.of(DEFENSE);
//     else if (defenseState == SNEAK_ATTACK && offenseState != SNEAK_ATTACK) return EnumSet.of(OFFENSE);
//   }
//   return EnumSet.of(OFFENSE, DEFENSE);
clear_first_strike_casualties_get_sides_to_clear :: proc(
	self: ^Clear_First_Strike_Casualties,
) -> []Battle_State_Side {
	props := game_data_get_properties(battle_state_get_game_data(self.battle_state))
	if properties_get_ww2_v2(props) {
		if self.offense_state == .SNEAK_ATTACK && self.defense_state != .SNEAK_ATTACK {
			return []Battle_State_Side{.DEFENSE}
		} else if self.defense_state == .SNEAK_ATTACK && self.offense_state != .SNEAK_ATTACK {
			return []Battle_State_Side{.OFFENSE}
		}
	}
	return []Battle_State_Side{.OFFENSE, .DEFENSE}
}

