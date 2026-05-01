package game

I_Delegate_Bridge :: struct {
	add_change:               proc(self: ^I_Delegate_Bridge, change: ^Change),
	enter_delegate_execution: proc(self: ^I_Delegate_Bridge),
}

// Java owners covered by this file:
//   - games.strategy.engine.delegate.IDelegateBridge

// games.strategy.engine.delegate.IDelegateBridge#addChange(games.strategy.engine.data.Change)
i_delegate_bridge_add_change :: proc(self: ^I_Delegate_Bridge, change: ^Change) {
	self.add_change(self, change)
}

// games.strategy.engine.delegate.IDelegateBridge#enterDelegateExecution()
i_delegate_bridge_enter_delegate_execution :: proc(self: ^I_Delegate_Bridge) {
	self.enter_delegate_execution(self)
}

// games.strategy.engine.delegate.IDelegateBridge#getCostsForTuv(games.strategy.engine.data.GamePlayer)
// Java default: return new TuvCostsCalculator().getCostsForTuv(player);
i_delegate_bridge_get_costs_for_tuv :: proc(
	self: ^I_Delegate_Bridge,
	player: ^Game_Player,
) -> map[^Unit_Type]i32 {
	calc := tuv_costs_calculator_new()
	return tuv_costs_calculator_get_costs_for_tuv(calc, player)
}

