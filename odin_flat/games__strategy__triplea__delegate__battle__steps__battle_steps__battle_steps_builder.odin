package game

Battle_Steps_Battle_Steps_Builder :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.BattleSteps$BattleStepsBuilder

battle_steps_battle_steps_builder_new :: proc() -> ^Battle_Steps_Battle_Steps_Builder {
	return new(Battle_Steps_Battle_Steps_Builder)
}

battle_steps_battle_steps_builder_battle_actions :: proc(self: ^Battle_Steps_Battle_Steps_Builder, battle_actions: ^Battle_Actions) -> ^Battle_Steps_Battle_Steps_Builder {
	self.battle_actions = battle_actions
	return self
}

battle_steps_battle_steps_builder_battle_state :: proc(self: ^Battle_Steps_Battle_Steps_Builder, battle_state: ^Battle_State) -> ^Battle_Steps_Battle_Steps_Builder {
	self.battle_state = battle_state
	return self
}

battle_steps_battle_steps_builder_build :: proc(self: ^Battle_Steps_Battle_Steps_Builder) -> ^Battle_Steps {
	return battle_steps_new(self.battle_state, self.battle_actions)
}

