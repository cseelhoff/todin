package game

Execution_Stack :: struct {
	current_step: ^I_Executable,
	deque:        [dynamic]^I_Executable,
}

