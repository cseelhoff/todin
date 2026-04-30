package game

Base_Delegate_State :: struct {
	start_base_steps_finished: bool,
	end_base_steps_finished:   bool,
}

base_delegate_state_new :: proc() -> ^Base_Delegate_State {
	s := new(Base_Delegate_State)
	s.start_base_steps_finished = false
	s.end_base_steps_finished = false
	return s
}

