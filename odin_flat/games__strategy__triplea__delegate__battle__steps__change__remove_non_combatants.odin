package game

Remove_Non_Combatants :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

remove_non_combatants_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Remove_Non_Combatants {
	self := new(Remove_Non_Combatants)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

remove_non_combatants_get_all_step_details :: proc(
	self: ^Remove_Non_Combatants,
) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

remove_non_combatants_get_order :: proc(
	self: ^Remove_Non_Combatants,
) -> Battle_Step_Order {
	return .REMOVE_NON_COMBATANTS
}

// Java: private void removeNonCombatants(BattleState.Side side, IDelegateBridge bridge) {
//   final Collection<Unit> nonCombatants = battleState.removeNonCombatants(side);
//   if (nonCombatants.isEmpty()) return;
//   bridge.getDisplayChannelBroadcaster()
//         .changedUnitsNotification(
//             battleState.getBattleId(), battleState.getPlayer(side), nonCombatants, null, null);
// }
remove_non_combatants_remove_non_combatants :: proc(
	self: ^Remove_Non_Combatants,
	side: Battle_State_Side,
	bridge: ^I_Delegate_Bridge,
) {
	non_combatants := battle_state_remove_non_combatants(self.battle_state, side)
	if len(non_combatants) == 0 {
		return
	}
	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_changed_units_notification(
		display,
		battle_state_get_battle_id(self.battle_state),
		battle_state_get_player(self.battle_state, side),
		non_combatants,
		nil,
		nil,
	)
}

