package game

Must_Fight_Battle_1 :: struct {}

must_fight_battle_1_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_1 {
	self := new(Must_Fight_Battle_1)
	_ = outer
	return self
}
