package game

Clear_Bombardment_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.ClearBombardmentCasualties

clear_bombardment_casualties_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Clear_Bombardment_Casualties {
	self := new(Clear_Bombardment_Casualties)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

clear_bombardment_casualties_get_order :: proc(
	self: ^Clear_Bombardment_Casualties,
) -> Battle_Step_Order {
	return .NAVAL_BOMBARDMENT_REMOVE_CASUALTIES
}

// Java: return battleState.getStatus().isFirstRound()
//          && !battleState.getBombardingUnits().isEmpty()
//          && !battleState.getBattleSite().isWater();
clear_bombardment_casualties_can_bombardment_occur :: proc(
	self: ^Clear_Bombardment_Casualties,
) -> bool {
	if !battle_status_is_first_round(battle_state_get_status(self.battle_state)) {
		return false
	}
	if len(battle_state_get_bombarding_units(self.battle_state)) == 0 {
		return false
	}
	if territory_is_water(battle_state_get_battle_site(self.battle_state)) {
		return false
	}
	return true
}

// Java: return !Properties.getNavalBombardCasualtiesReturnFire(
//                 battleState.getGameData().getProperties());
clear_bombardment_casualties_clear_casualties :: proc(
	self: ^Clear_Bombardment_Casualties,
) -> bool {
	return !properties_get_naval_bombard_casualties_return_fire(
		game_data_get_properties(battle_state_get_game_data(self.battle_state)),
	)
}

// Java: return canBombardmentOccur() && clearCasualties()
//          ? List.of(new StepDetails(REMOVE_BOMBARDMENT_CASUALTIES, this))
//          : List.of();
clear_bombardment_casualties_get_all_step_details :: proc(
	self: ^Clear_Bombardment_Casualties,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	if clear_bombardment_casualties_can_bombardment_occur(self) &&
	   clear_bombardment_casualties_clear_casualties(self) {
		append(
			&out,
			battle_step_step_details_new(
				BATTLE_STEP_REMOVE_BOMBARDMENT_CASUALTIES,
				&self.battle_step,
			),
		)
	}
	return out
}

// Java: if (canBombardmentOccur() && clearCasualties()) {
//           battleActions.clearWaitingToDieAndDamagedChangesInto(
//               bridge, BattleState.Side.DEFENSE);
//       }
clear_bombardment_casualties_execute :: proc(
	self: ^Clear_Bombardment_Casualties,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	if clear_bombardment_casualties_can_bombardment_occur(self) &&
	   clear_bombardment_casualties_clear_casualties(self) {
		battle_actions_clear_waiting_to_die_and_damaged_changes_into(
			self.battle_actions,
			bridge,
			.DEFENSE,
		)
	}
}

