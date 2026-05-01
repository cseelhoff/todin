package game

Execution_Stack :: struct {
	current_step: ^I_Executable,
	deque:        [dynamic]^I_Executable,
}

// Constructor: ExecutionStack()
execution_stack_new :: proc() -> ^Execution_Stack {
	s := new(Execution_Stack)
	s.current_step = nil
	s.deque = make([dynamic]^I_Executable)
	return s
}

// boolean isEmpty()
execution_stack_is_empty :: proc(self: ^Execution_Stack) -> bool {
	return len(self.deque) == 0
}

// boolean isExecuting()
execution_stack_is_executing :: proc(self: ^Execution_Stack) -> bool {
	return self.current_step != nil
}

// void push(IExecutable executable) — pushes onto the head of the deque.
// We model the deque with the end of the dynamic array as the head, so
// appending is equivalent to ArrayDeque.push.
execution_stack_push_one :: proc(self: ^Execution_Stack, executable: ^I_Executable) {
	append(&self.deque, executable)
}

// void push(Collection<IExecutable> executables) — iterates the collection
// and pushes each element onto the head of the deque (matching Java's
// executables.forEach(deque::push)).
execution_stack_push_all :: proc(self: ^Execution_Stack, executables: []^I_Executable) {
	for e in executables {
		append(&self.deque, e)
	}
}

