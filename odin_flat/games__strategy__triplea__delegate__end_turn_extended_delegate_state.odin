package game

End_Turn_Extended_Delegate_State :: struct {
	super_state:             rawptr,
	need_to_initialize:      bool,
	has_posted_turn_summary: bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.EndTurnExtendedDelegateState

end_turn_extended_delegate_state_new :: proc() -> ^End_Turn_Extended_Delegate_State {
	self := new(End_Turn_Extended_Delegate_State)
	return self
}

