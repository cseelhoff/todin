package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.MustFightBattle$28

Must_Fight_Battle_28 :: struct {
	using i_executable: I_Executable,
	this_0:             ^Must_Fight_Battle,
}

must_fight_battle_28_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_28 {
	self := new(Must_Fight_Battle_28)
	self.this_0 = outer
	return self
}

must_fight_battle_28_execute :: proc(self: ^Must_Fight_Battle_28, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	must_fight_battle_push_fight_loop_on_stack(self.this_0)
}

