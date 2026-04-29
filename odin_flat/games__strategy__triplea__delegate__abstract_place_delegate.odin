package game

Abstract_Place_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	produced:   map[^Territory][dynamic]^Unit,
	placements: [dynamic]^Undoable_Placement,
}
