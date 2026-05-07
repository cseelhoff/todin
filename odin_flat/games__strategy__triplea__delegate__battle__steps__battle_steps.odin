package game

import "core:slice"

Battle_Steps :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

battle_steps_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Battle_Steps {
	self := new(Battle_Steps)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

battle_steps_builder :: proc() -> ^Battle_Steps_Battle_Steps_Builder {
	return battle_steps_battle_steps_builder_new()
}

// Java: games.strategy.triplea.delegate.battle.steps.BattleSteps#get()
//
//   public List<BattleStep.StepDetails> get() {
//     return BattleStep.getAll(battleState, battleActions).stream()
//         .sorted(Comparator.comparing(BattleStep::getOrder))
//         .flatMap(step -> step.getAllStepDetails().stream())
//         .collect(Collectors.toList());
//   }
battle_steps_get :: proc(self: ^Battle_Steps) -> [dynamic]^Battle_Step_Step_Details {
	steps := battle_step_get_all(self.battle_state, self.battle_actions)
	slice.sort_by(steps[:], proc(a, b: ^Battle_Step) -> bool {
		return int(battle_step_get_order(a)) < int(battle_step_get_order(b))
	})
	result := make([dynamic]^Battle_Step_Step_Details)
	for step in steps {
		details := battle_step_get_all_step_details(step)
		for d in details {
			append(&result, d)
		}
	}
	return result
}

