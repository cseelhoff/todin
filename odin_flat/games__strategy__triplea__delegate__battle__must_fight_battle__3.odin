package game

Must_Fight_Battle_3 :: struct {}

must_fight_battle_3_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_3 {
	self := new(Must_Fight_Battle_3)
	_ = outer
	return self
}
