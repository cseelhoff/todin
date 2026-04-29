package game

Undoable_Placement :: struct {
	using parent:       Abstract_Undoable_Move,
	place_territory:    ^Territory,
	producer_territory: ^Territory,
}

