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

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#retreat(
//   games.strategy.engine.delegate.IDelegateBridge,
//   games.strategy.triplea.delegate.battle.steps.retreat.Retreater,
//   games.strategy.engine.data.Territory)
//
// Retreater is dispatched via its proc-pointer vtable. The websocket
// branches (sendMessage(NotifyUnitsRetreatingMessage / NotifyRetreatMessage))
// are dormant for snapshot runs; we always take the broadcaster path,
// mirroring the convention used in evader_retreat.odin and
// remove_non_combatants.odin.
offensive_general_retreat_retreat :: proc(
	self: ^Offensive_General_Retreat,
	bridge: ^I_Delegate_Bridge,
	retreater: ^Retreater,
	retreat_to: ^Territory,
) {
	retreat_units := retreater.get_retreat_units(retreater.self_raw)

	sound_utils_play_retreat_type(
		battle_state_get_player(self.battle_state, .OFFENSE),
		retreat_units,
		retreater.get_retreat_type(retreater.self_raw),
		bridge,
	)

	retreat_changes := retreater.compute_changes(retreater.self_raw, retreat_to)
	i_delegate_bridge_add_change(bridge, retreat_changes_get_change(retreat_changes))

	for history_child in retreat_changes_get_history_text(retreat_changes) {
		offensive_general_retreat_lambda__retreat__1(bridge, history_child)
	}

	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	alive_offense := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	if len(alive_offense) == 0 {
		battle_actions_end_battle(self.battle_actions, .DEFENDER, bridge)
	} else {
		display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
		i_display_notify_retreat_units(
			display,
			battle_state_get_battle_id(self.battle_state),
			retreat_units,
		)
	}

	offense_player := battle_state_get_player(self.battle_state, .OFFENSE)
	short_message := fmt.aprintf(
		"%s%s",
		offense_player.named.base.name,
		offensive_general_retreat_get_short_broadcast_suffix(self, retreater.get_retreat_type(retreater.self_raw)),
	)
	long_message := fmt.aprintf(
		"%s%s",
		offense_player.named.base.name,
		offensive_general_retreat_get_long_broadcast_suffix(self, retreater.get_retreat_type(retreater.self_raw), retreat_to),
	)

	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_notify_retreat(
		display,
		short_message,
		long_message,
		offensive_general_retreat_get_name(self),
		offense_player,
	)
}

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#canAttackerRetreatPartialAmphib()
//
// Java:
//   if (!Properties.getPartialAmphibiousRetreat(battleState.getGameData().getProperties())) {
//     return false;
//   }
//   return battleState.filterUnits(ALIVE, OFFENSE).stream()
//       .filter(Matches.unitIsLand())
//       .anyMatch(Matches.unitWasNotAmphibious());
offensive_general_retreat_can_attacker_retreat_partial_amphib :: proc(self: ^Offensive_General_Retreat) -> bool {
	game_data := battle_state_get_game_data(self.battle_state)
	if !properties_get_partial_amphibious_retreat(game_data_get_properties(game_data)) {
		return false
	}
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	land_p, land_c := matches_unit_is_land()
	not_amphib_p, not_amphib_c := matches_unit_was_not_amphibious()
	for u in units {
		if land_p(land_c, u) && not_amphib_p(not_amphib_c, u) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#canAttackerRetreatAmphibPlanes()
//
// Java:
//   final GameState gameData = battleState.getGameData();
//   return (Properties.getWW2V2(gameData.getProperties())
//           || Properties.getAttackerRetreatPlanes(gameData.getProperties())
//           || Properties.getPartialAmphibiousRetreat(gameData.getProperties()))
//       && battleState.filterUnits(ALIVE, OFFENSE).stream().anyMatch(Matches.unitIsAir());
offensive_general_retreat_can_attacker_retreat_amphib_planes :: proc(self: ^Offensive_General_Retreat) -> bool {
	game_data := battle_state_get_game_data(self.battle_state)
	props := game_data_get_properties(game_data)
	if !(properties_get_ww2_v2(props) ||
	     properties_get_attacker_retreat_planes(props) ||
	     properties_get_partial_amphibious_retreat(props)) {
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

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#lambda$retreatUnits$0(
//   games.strategy.engine.delegate.IDelegateBridge,
//   games.strategy.triplea.delegate.battle.steps.retreat.Retreater,
//   games.strategy.engine.data.Territory)
//
// Java (from retreatUnits() ifPresent):
//   retreatTo -> retreat(bridge, retreater, retreatTo)
offensive_general_retreat_lambda__retreat_units__0 :: proc(
	self: ^Offensive_General_Retreat,
	bridge: ^I_Delegate_Bridge,
	retreater: ^Retreater,
	retreat_to: ^Territory,
) {
	offensive_general_retreat_retreat(self, bridge, retreater, retreat_to)
}

// games.strategy.triplea.delegate.battle.steps.retreat.OffensiveGeneralRetreat#getAmphibiousRetreater()
//
// Java:
//   if (canAttackerRetreatPartialAmphib()) {
//     return new RetreaterPartialAmphibious(battleState);
//   } else if (canAttackerRetreatAmphibPlanes()) {
//     return new RetreaterAirAmphibious(battleState);
//   }
//   return null;
//
// Java returns the Retreater interface; Odin wraps the concrete subtype
// in a Retreater vtable struct with self_raw pointing at it. The vtable
// proc-pointers stay nil here, mirroring retreater_general_new (whose
// embedded Retreater is also unwired): the partial-amphibious and
// air-amphibious dispatch methods are not flagged
// actually_called_in_ai_test, so snapshot runs never invoke them.
offensive_general_retreat_get_amphibious_retreater :: proc(self: ^Offensive_General_Retreat) -> ^Retreater {
	if offensive_general_retreat_can_attacker_retreat_partial_amphib(self) {
		concrete := retreater_partial_amphibious_new(self.battle_state)
		r := new(Retreater)
		r.self_raw = concrete
		return r
	} else if offensive_general_retreat_can_attacker_retreat_amphib_planes(self) {
		concrete := retreater_air_amphibious_new(self.battle_state)
		r := new(Retreater)
		r.self_raw = concrete
		return r
	}
	return nil
}

