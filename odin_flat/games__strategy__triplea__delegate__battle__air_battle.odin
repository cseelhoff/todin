package game

Air_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	stack: Execution_Stack,
	steps: [dynamic]string,
	defending_waiting_to_die: [dynamic]^Unit,
	attacking_waiting_to_die: [dynamic]^Unit,
	intercept: bool,
	max_rounds: i32,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.AirBattle

// games.strategy.triplea.delegate.battle.AirBattle#attackingGroundSeaBattleEscorts
air_battle_attacking_ground_sea_battle_escorts :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_unit_can_air_battle()
}

// games.strategy.triplea.delegate.battle.AirBattle#getDefendingUnits
air_battle_get_defending_units :: proc(self: ^Air_Battle) -> [dynamic]^Unit {
	return abstract_battle_get_defending_units(&self.abstract_battle)
}

