package game

// Java owners covered by this file:
//   - games.strategy.triplea.odds.calculator.DummyPlayer

Dummy_Player :: struct {
	using abstract_ai: Abstract_Ai,
	keep_at_least_one_land:   bool,
	retreat_after_round:      i32,
	retreat_after_x_units_left: i32,
	retreat_when_only_air_left: bool,
	bridge:                   ^Dummy_Delegate_Bridge,
	is_attacker:              bool,
	order_of_losses:          [dynamic]^Unit,
}

