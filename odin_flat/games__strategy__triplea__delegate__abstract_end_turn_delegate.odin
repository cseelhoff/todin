package game

Abstract_End_Turn_Delegate :: struct {
	using parent: Base_Triple_A_Delegate,
	need_to_initialize: bool,
	has_posted_turn_summary: bool,
}
