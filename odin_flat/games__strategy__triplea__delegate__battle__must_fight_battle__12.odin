package game

Must_Fight_Battle_12 :: struct {}

must_fight_battle_12_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_12 {
	self := new(Must_Fight_Battle_12)
	_ = outer
	return self
}
