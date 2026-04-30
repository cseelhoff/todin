package game

Abstract_Undoable_Move :: struct {
	change: ^Composite_Change,
	index:  i32,
	units:  [dynamic]^Unit,
}

abstract_undoable_move_new :: proc(change: ^Composite_Change, units: [dynamic]^Unit) -> ^Abstract_Undoable_Move {
	self := new(Abstract_Undoable_Move)
	self.change = change
	self.units = units
	return self
}

abstract_undoable_move_set_index :: proc(self: ^Abstract_Undoable_Move, index: i32) {
	self.index = index
}

