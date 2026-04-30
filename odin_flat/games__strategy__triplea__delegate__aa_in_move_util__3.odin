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

aa_in_move_util_3_new :: proc(
	this_0: ^Aa_In_Move_Util,
	location: ^Territory,
	targets: [dynamic]^Unit,
	current_move: ^Undoable_Move,
) -> ^Aa_In_Move_Util_3 {
	self := new(Aa_In_Move_Util_3)
	self.this_0 = this_0
	self.location = location
	self.targets = targets
	self.current_move = current_move
	return self
}

