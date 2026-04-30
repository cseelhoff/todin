package game

Must_Fight_Battle_5 :: struct {}

must_fight_battle_5_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_5 {
	self := new(Must_Fight_Battle_5)
	_ = outer
	return self
}
