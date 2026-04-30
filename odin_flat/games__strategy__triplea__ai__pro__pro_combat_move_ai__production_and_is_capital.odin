package game

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.ProCombatMoveAi$ProductionAndIsCapital

Pro_Combat_Move_Ai_Production_And_Is_Capital :: struct {
	production: i32,
	is_capital: i32,
}

pro_combat_move_ai_production_and_is_capital_new :: proc() -> ^Pro_Combat_Move_Ai_Production_And_Is_Capital {
	self := new(Pro_Combat_Move_Ai_Production_And_Is_Capital)
	self.production = 0
	self.is_capital = 0
	return self
}

