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

