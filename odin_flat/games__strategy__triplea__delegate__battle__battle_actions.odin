package game

Battle_Actions :: struct {}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.BattleActions

// Java's BattleActions.getRemotePlayer default method may construct
// `new WeakAi(name)` and return it as a Player. In Odin, Weak_Ai does
// not embed the Player vtable directly, so we wrap a freshly-allocated
// Weak_Ai inside a small Player wrapper whose proc fields delegate to
// the AI's AbstractBasePlayer/AbstractAi behavior.

@(private = "file")
Weak_Ai_Player_Wrapper :: struct {
	using player: Player,
	ai:           ^Weak_Ai,
}

@(private = "file")
weak_ai_player_get_name :: proc(self: ^Player) -> string {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.name
}

@(private = "file")
weak_ai_player_get_player_label :: proc(self: ^Player) -> string {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.player_label
}

@(private = "file")
weak_ai_player_is_ai :: proc(self: ^Player) -> bool {
	return true
}

@(private = "file")
weak_ai_player_get_game_player :: proc(self: ^Player) -> ^Game_Player {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.game_player
}

@(private = "file")
weak_ai_player_initialize :: proc(
	self: ^Player,
	bridge: ^Player_Bridge,
	game_player: ^Game_Player,
) {
	w := cast(^Weak_Ai_Player_Wrapper)self
	w.ai.player_bridge = bridge
	w.ai.game_player = game_player
}

// games.strategy.triplea.delegate.battle.BattleActions#getRemotePlayer(
//     games.strategy.engine.data.GamePlayer,
//     games.strategy.engine.delegate.IDelegateBridge)
//
//   default Player getRemotePlayer(final GamePlayer player, final IDelegateBridge bridge) {
//     // if its the null player, return a do nothing proxy
//     if (player.isNull()) {
//       return new WeakAi(player.getName());
//     }
//     return bridge.getRemotePlayer(player);
//   }
battle_actions_get_remote_player :: proc(
	self: ^Battle_Actions,
	player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
) -> ^Player {
	if game_player_is_null(player) {
		w := new(Weak_Ai_Player_Wrapper)
		w.ai = weak_ai_new(player.name)
		w.get_name = weak_ai_player_get_name
		w.get_player_label = weak_ai_player_get_player_label
		w.is_ai = weak_ai_player_is_ai
		w.get_game_player = weak_ai_player_get_game_player
		w.initialize = weak_ai_player_initialize
		return &w.player
	}
	return i_delegate_bridge_get_remote_player(bridge, player)
}

// games.strategy.triplea.delegate.battle.BattleActions#clearWaitingToDieAndDamagedChangesInto(IDelegateBridge, Side[])
//   Forwarder to MustFightBattle (the only concrete impl on the AI
//   snapshot path).
battle_actions_clear_waiting_to_die_and_damaged_changes_into :: proc(
	self: ^Battle_Actions,
	bridge: ^I_Delegate_Bridge,
	sides: ..Battle_State_Side,
) {
	must_fight_battle_clear_waiting_to_die_and_damaged_changes_into(
		cast(^Must_Fight_Battle)self,
		bridge,
		..sides,
	)
}

// games.strategy.triplea.delegate.battle.BattleActions#endBattle(IBattle.WhoWon, IDelegateBridge)
//   Forwarder; MustFightBattle owns the implementation.
battle_actions_end_battle :: proc(
	self: ^Battle_Actions,
	who_won: I_Battle_Who_Won,
	bridge: ^I_Delegate_Bridge,
) {
	must_fight_battle_end_battle_who_won(cast(^Must_Fight_Battle)self, who_won, bridge)
}

// games.strategy.triplea.delegate.battle.BattleActions#removeUnits(Collection<Unit>, IDelegateBridge, Territory, Side)
//   Forwarder; MustFightBattle owns the implementation.
battle_actions_remove_units :: proc(
	self: ^Battle_Actions,
	killed: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	battle_site: ^Territory,
	side: Battle_State_Side,
) {
	must_fight_battle_remove_units(
		cast(^Must_Fight_Battle)self,
		killed,
		bridge,
		battle_site,
		side,
	)
}

// games.strategy.triplea.delegate.battle.BattleActions#queryRetreatTerritory(...)
//   Forwarder to MustFightBattle implementation.
battle_actions_query_retreat_territory :: proc(
	self: ^Battle_Actions,
	battle_state: ^Battle_State,
	bridge: ^I_Delegate_Bridge,
	retreating_player: ^Game_Player,
	available_territories: [dynamic]^Territory,
	text: string,
) -> ^Territory {
	return must_fight_battle_query_retreat_territory(
		cast(^Must_Fight_Battle)self,
		battle_state,
		bridge,
		retreating_player,
		available_territories,
		text,
	)
}

// games.strategy.triplea.delegate.battle.BattleActions#querySubmergeTerritory(...)
//   Forwarder to MustFightBattle implementation.
battle_actions_query_submerge_territory :: proc(
	self: ^Battle_Actions,
	battle_state: ^Battle_State,
	bridge: ^I_Delegate_Bridge,
	retreating_player: ^Game_Player,
	available_territories: [dynamic]^Territory,
	text: string,
) -> ^Territory {
	return must_fight_battle_query_submerge_territory(
		cast(^Must_Fight_Battle)self,
		battle_state,
		bridge,
		retreating_player,
		available_territories,
		text,
	)
}
