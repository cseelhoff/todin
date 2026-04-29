package game

Abstract_Move_Delegate :: struct {
	using parent: Base_Triple_A_Delegate,
	moves_to_undo: [dynamic]^Undoable_Move,
	temp_move_performer: ^Move_Performer,
}

Abstract_Move_Delegate_Move_Type :: enum {
	DEFAULT,
	SPECIAL,
}

