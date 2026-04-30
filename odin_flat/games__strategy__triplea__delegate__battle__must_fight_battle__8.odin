package game

Must_Fight_Battle_8 :: struct {}

must_fight_battle_8_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_8 {
	self := new(Must_Fight_Battle_8)
	_ = outer
	return self
}
