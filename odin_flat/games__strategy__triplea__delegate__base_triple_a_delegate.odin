package game

Base_Triple_A_Delegate :: struct {
	using abstract_delegate: Abstract_Delegate,
	start_base_steps_finished: bool,
	end_base_steps_finished:   bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.BaseTripleADelegate

// games.strategy.triplea.delegate.BaseTripleADelegate#<init>()
// Java's implicit no-arg constructor. All fields default to their zero
// value (false for the two finished flags); the embedded
// Abstract_Delegate is also zero-initialized.
base_triple_a_delegate_new :: proc() -> ^Base_Triple_A_Delegate {
	self := new(Base_Triple_A_Delegate)
	return self
}

// games.strategy.triplea.delegate.BaseTripleADelegate#saveState()
// Builds a Base_Delegate_State capturing the start/end "finished" flags.
base_triple_a_delegate_save_state :: proc(self: ^Base_Triple_A_Delegate) -> ^Base_Delegate_State {
	state := base_delegate_state_new()
	state.start_base_steps_finished = self.start_base_steps_finished
	state.end_base_steps_finished = self.end_base_steps_finished
	return state
}

base_triple_a_delegate_load_state :: proc(self: ^Base_Triple_A_Delegate, state: ^Base_Delegate_State) {
	self.start_base_steps_finished = state.start_base_steps_finished
	self.end_base_steps_finished = state.end_base_steps_finished
}

