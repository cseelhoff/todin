package game

Must_Fight_Battle_20 :: struct {}

must_fight_battle_20_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_20 {
	self := new(Must_Fight_Battle_20)
	_ = outer
	return self
}
