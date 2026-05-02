package game

// Java owner: games.strategy.triplea.delegate.InitializationDelegate

Initialization_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize: bool,
}

// games.strategy.triplea.delegate.InitializationDelegate#<init>()
// Java's implicit no-arg constructor. The only declared field
// `needToInitialize` has the Java initializer `= true`; embedded
// Base_Triple_A_Delegate is zero-initialized.
initialization_delegate_new :: proc() -> ^Initialization_Delegate {
	self := new(Initialization_Delegate)
	self.need_to_initialize = true
	return self
}

// games.strategy.triplea.delegate.InitializationDelegate#saveState()
// Builds an InitializationExtendedDelegateState. `superState` is the
// parent delegate's save_state (Base_Triple_A_Delegate has no
// override; this resolves to base_triple_a_delegate_save_state).
// `super_state` on the state struct is rawptr so a
// Base_Delegate_State pointer can be packed in.
initialization_delegate_save_state :: proc(self: ^Initialization_Delegate) -> ^Initialization_Extended_Delegate_State {
	state := initialization_extended_delegate_state_new()
	state.super_state = rawptr(base_triple_a_delegate_save_state(&self.base_triple_a_delegate))
	state.need_to_initialize = self.need_to_initialize
	return state
}

// games.strategy.triplea.delegate.InitializationDelegate#getRemoteType()
// Java returns `null` (no remote interface). Odin mirrors that with the
// zero `typeid` value.
initialization_delegate_get_remote_type :: proc(self: ^Initialization_Delegate) -> typeid {
	return nil
}

// games.strategy.triplea.delegate.InitializationDelegate#loadState(java.io.Serializable)
// Restores delegate state from an InitializationExtendedDelegateState.
// Mirrors the Java cast-and-assign, then forwards `superState` to the
// parent delegate's loadState (BaseTripleADelegate has no override, so
// this resolves to AbstractDelegate's via Base_Triple_A_Delegate.load_state).
initialization_delegate_load_state :: proc(
	self: ^Initialization_Delegate,
	state: ^Initialization_Extended_Delegate_State,
) {
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)state.super_state,
	)
	self.need_to_initialize = state.need_to_initialize
}

// games.strategy.triplea.delegate.InitializationDelegate#initAiStartingBonusIncome(games.strategy.engine.delegate.IDelegateBridge)
// Static helper. Iterates every player on the bridge's data and gives
// each their AI starting bonus income via BonusIncomeUtils.
initialization_delegate_init_ai_starting_bonus_income :: proc(bridge: ^I_Delegate_Bridge) {
	players := player_list_get_players(
		game_data_get_player_list(i_delegate_bridge_get_data(bridge)),
	)
	for player in players {
		bonus_income_utils_add_bonus_income(
			resource_collection_get_resources_copy(game_player_get_resources(player)),
			bridge,
			player,
		)
	}
}

