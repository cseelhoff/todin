package game

Must_Fight_Battle_17 :: struct {}

must_fight_battle_17_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_17 {
	self := new(Must_Fight_Battle_17)
	_ = outer
	return self
}
