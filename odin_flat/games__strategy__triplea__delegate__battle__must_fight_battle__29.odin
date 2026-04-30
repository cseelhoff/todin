package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.MustFightBattle$29

Must_Fight_Battle_29 :: struct {
	using i_executable: I_Executable,
	this_0:             ^Must_Fight_Battle,
	loop:               ^I_Executable,
}

must_fight_battle_29_new :: proc(outer: ^Must_Fight_Battle, executable: ^I_Executable) -> ^Must_Fight_Battle_29 {
	self := new(Must_Fight_Battle_29)
	self.this_0 = outer
	self.loop = executable
	return self
}

