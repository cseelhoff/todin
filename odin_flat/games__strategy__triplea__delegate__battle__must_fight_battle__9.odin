package game

Must_Fight_Battle_9 :: struct {}

must_fight_battle_9_new :: proc(outer: ^Must_Fight_Battle) -> ^Must_Fight_Battle_9 {
	self := new(Must_Fight_Battle_9)
	_ = outer
	return self
}
