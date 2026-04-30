package game

Must_Fight_Battle_7 :: struct {}

must_fight_battle_7_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_7 {
	self := new(Must_Fight_Battle_7)
	_ = outer
	return self
}
