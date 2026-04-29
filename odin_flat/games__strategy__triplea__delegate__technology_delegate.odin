package game

Technology_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	tech_cost:          i32,
	techs:              map[^Game_Player][dynamic]^Tech_Advance,
	tech_category:      ^Technology_Frontier,
	need_to_initialize: bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.TechnologyDelegate

