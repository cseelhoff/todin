package game

Must_Fight_Battle_15 :: struct {}

must_fight_battle_15_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_15 {
	self := new(Must_Fight_Battle_15)
	_ = outer
	return self
}
