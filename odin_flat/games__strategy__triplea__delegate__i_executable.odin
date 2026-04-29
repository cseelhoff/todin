package game

I_Executable :: struct {
	execute: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge),
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.IExecutable

