package game

Base_Triple_A_Delegate :: struct {
	using abstract_delegate: Abstract_Delegate,
	start_base_steps_finished: bool,
	end_base_steps_finished:   bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.BaseTripleADelegate

base_triple_a_delegate_load_state :: proc(self: ^Base_Triple_A_Delegate, state: ^Base_Delegate_State) {
	self.start_base_steps_finished = state.start_base_steps_finished
	self.end_base_steps_finished = state.end_base_steps_finished
}

