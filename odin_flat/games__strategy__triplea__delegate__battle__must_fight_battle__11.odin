package game

Must_Fight_Battle_11 :: struct {}

must_fight_battle_11_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_11 {
	self := new(Must_Fight_Battle_11)
	_ = outer
	return self
}
