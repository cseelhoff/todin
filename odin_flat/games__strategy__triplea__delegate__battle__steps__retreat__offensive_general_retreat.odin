package game

import "core:fmt"

Offensive_General_Retreat :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

offensive_general_retreat_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Offensive_General_Retreat {
	self := new(Offensive_General_Retreat)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

offensive_general_retreat_get_order :: proc(self: ^Offensive_General_Retreat) -> Battle_Step_Order {
	return Battle_Step_Order.OFFENSIVE_GENERAL_RETREAT
}

offensive_general_retreat_get_short_broadcast_suffix :: proc(self: ^Offensive_General_Retreat, retreat_type: Must_Fight_Battle_Retreat_Type) -> string {
	switch retreat_type {
	case .PARTIAL_AMPHIB:
		return " retreats non-amphibious units"
	case .PLANES:
		return " retreats planes"
	case .DEFAULT, .SUBS:
		return " retreats"
	}
	return " retreats"
}

offensive_general_retreat_get_long_broadcast_suffix :: proc(self: ^Offensive_General_Retreat, retreat_type: Must_Fight_Battle_Retreat_Type, retreat_to: ^Territory) -> string {
	switch retreat_type {
	case .PARTIAL_AMPHIB:
		return " retreats non-amphibious units"
	case .PLANES:
		return " retreats planes"
	case .DEFAULT, .SUBS:
		name := default_named_get_name(&retreat_to.named_attachable.default_named)
		return fmt.aprintf(" retreats all units to %s", name)
	}
	return ""
}

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#canAttackerRetreatSeaPlanes()
//
// Java:
//   return battleState.getBattleSite().isWater()
//       && battleState.filterUnits(ALIVE, OFFENSE).stream().anyMatch(Matches.unitIsAir());
offensive_general_retreat_can_attacker_retreat_sea_planes :: proc(self: ^Offensive_General_Retreat) -> bool {
	if !territory_is_water(battle_state_get_battle_site(self.battle_state)) {
		return false
	}
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	air_p, air_c := matches_unit_is_air()
	for u in units {
		if air_p(air_c, u) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#getName()
//
// Java:
//   return battleState.getPlayer(OFFENSE).getName() + ATTACKER_WITHDRAW;
offensive_general_retreat_get_name :: proc(self: ^Offensive_General_Retreat) -> string {
	player := battle_state_get_player(self.battle_state, .OFFENSE)
	return fmt.aprintf("%s%s", player.named.base.name, BATTLE_STEP_ATTACKER_WITHDRAW)
}

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#getQueryText(MustFightBattle.RetreatType)
//
// Java switch on retreatType: DEFAULT/default -> " retreat?",
// PARTIAL_AMPHIB -> " retreat non-amphibious units?",
// PLANES -> " retreat planes?".
offensive_general_retreat_get_query_text :: proc(self: ^Offensive_General_Retreat, retreat_type: Must_Fight_Battle_Retreat_Type) -> string {
	player := battle_state_get_player(self.battle_state, .OFFENSE)
	switch retreat_type {
	case .PARTIAL_AMPHIB:
		return fmt.aprintf("%s retreat non-amphibious units?", player.named.base.name)
	case .PLANES:
		return fmt.aprintf("%s retreat planes?", player.named.base.name)
	case .DEFAULT, .SUBS:
		return fmt.aprintf("%s retreat?", player.named.base.name)
	}
	return fmt.aprintf("%s retreat?", player.named.base.name)
}

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#lambda$retreat$1(
//   games.strategy.engine.delegate.IDelegateBridge,
//   games.strategy.triplea.delegate.battle.steps.retreat.Retreater$RetreatHistoryChild)
//
// Java (from retreat() forEach):
//   historyChild -> bridge.getHistoryWriter()
//                       .addChildToEvent(historyChild.getText(), historyChild.getUnits())
offensive_general_retreat_lambda__retreat__1 :: proc(bridge: ^I_Delegate_Bridge, history_child: ^Retreater_Retreat_History_Child) {
	writer := i_delegate_bridge_get_history_writer(bridge)
	history_writer_add_child_to_event(
		writer,
		retreat_history_child_get_text(history_child),
		retreat_history_child_get_units(history_child),
	)
}

