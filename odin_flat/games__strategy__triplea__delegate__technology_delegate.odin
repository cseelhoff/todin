package game

Technology_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	tech_cost:          i32,
	techs:              map[^Game_Player][dynamic]^Tech_Advance,
	tech_category:      ^Technology_Frontier,
	need_to_initialize: bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.TechnologyDelegate

// games.strategy.triplea.delegate.TechnologyDelegate#initialize(String, String)
// Calls super.initialize(name, displayName), then allocates the per-player
// tech-advance map and resets techCost to -1 (matching Java).
technology_delegate_initialize :: proc(self: ^Technology_Delegate, name: string, display_name: string) {
	abstract_delegate_initialize(&self.abstract_delegate, name, display_name)
	self.techs = make(map[^Game_Player][dynamic]^Tech_Advance)
	self.tech_cost = -1
}

// games.strategy.triplea.delegate.TechnologyDelegate#getAdvances(GamePlayer)
// Returns the advances list mapped to the given player, or nil when the
// techs map has not been initialized or has no entry for the player.
// Java: `techs == null ? null : techs.get(player)`.
technology_delegate_get_advances :: proc(self: ^Technology_Delegate, player: ^Game_Player) -> [dynamic]^Tech_Advance {
	if self.techs == nil {
		return nil
	}
	return self.techs[player]
}

// games.strategy.triplea.delegate.TechnologyDelegate#clearAdvances(GamePlayer)
// Removes any advances entry for the given player when the techs map is
// initialized. No-op otherwise.
technology_delegate_clear_advances :: proc(self: ^Technology_Delegate, player: ^Game_Player) {
	if self.techs != nil {
		delete_key(&self.techs, player)
	}
}

// games.strategy.triplea.delegate.TechnologyDelegate#getRemoteType()
// Java returns `Class<ITechDelegate>`; Odin returns the corresponding
// `typeid`, mirroring how the other delegates expose their remote types.
technology_delegate_get_remote_type :: proc(self: ^Technology_Delegate) -> typeid {
	return I_Tech_Delegate
}

// games.strategy.triplea.delegate.TechnologyDelegate#loadState(java.io.Serializable)
// Java casts the Serializable to TechnologyExtendedDelegateState, chains
// super.loadState with its superState, then restores needToInitialize and
// the techs map.
technology_delegate_load_state :: proc(
	self: ^Technology_Delegate,
	state: ^Technology_Extended_Delegate_State,
) {
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)state.super_state,
	)
	self.need_to_initialize = state.need_to_initialize
	self.techs = state.techs
}

