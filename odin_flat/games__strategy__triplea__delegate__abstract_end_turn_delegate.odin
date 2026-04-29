package game

Abstract_End_Turn_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize: bool,
	has_posted_turn_summary: bool,
}
