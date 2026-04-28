package game

Abstract_Undoable_Move :: struct {
	change: ^Composite_Change,
	index:  i32,
	units:  [dynamic]^Unit,
}

