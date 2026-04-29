package game

Abstract_Place_Delegate :: struct {
	using parent: Base_Triple_A_Delegate,
	produced:   map[^Territory][dynamic]^Unit,
	placements: [dynamic]^Undoable_Placement,
}
