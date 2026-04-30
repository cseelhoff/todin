package game

Must_Fight_Battle_21 :: struct {}

must_fight_battle_21_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_21 {
	self := new(Must_Fight_Battle_21)
	_ = outer
	return self
}
