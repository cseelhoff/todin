package game

Must_Fight_Battle_4 :: struct {}

must_fight_battle_4_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_4 {
	self := new(Must_Fight_Battle_4)
	_ = outer
	return self
}
