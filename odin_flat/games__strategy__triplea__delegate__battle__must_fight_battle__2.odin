package game

Must_Fight_Battle_2 :: struct {}

must_fight_battle_2_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_2 {
	self := new(Must_Fight_Battle_2)
	_ = outer
	return self
}
