package game

Undoable_Placement :: struct {
	using abstract_undoable_move: Abstract_Undoable_Move,
	place_territory:    ^Territory,
	producer_territory: ^Territory,
}

