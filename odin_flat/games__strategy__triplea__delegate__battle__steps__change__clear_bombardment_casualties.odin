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

