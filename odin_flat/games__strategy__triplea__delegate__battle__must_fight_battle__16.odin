package game

Must_Fight_Battle_16 :: struct {}

must_fight_battle_16_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_16 {
	self := new(Must_Fight_Battle_16)
	_ = outer
	return self
}
