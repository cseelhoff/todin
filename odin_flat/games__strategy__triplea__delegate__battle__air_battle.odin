package game

Air_Battle :: struct {
	using parent: Abstract_Battle,
	stack: Execution_Stack,
	steps: [dynamic]string,
	defending_waiting_to_die: [dynamic]^Unit,
	attacking_waiting_to_die: [dynamic]^Unit,
	intercept: bool,
	max_rounds: i32,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.AirBattle

