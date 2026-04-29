package game

// Anonymous IExecutable in AaInMoveUtil.populateExecutionStack.
// Captures the enclosing AaInMoveUtil, the territory location,
// the targets list, and the current UndoableMove.
Aa_In_Move_Util_3 :: struct {
	using i_executable: I_Executable,
	this_0:       ^Aa_In_Move_Util,
	location:     ^Territory,
	targets:      [dynamic]^Unit,
	current_move: ^Undoable_Move,
}

