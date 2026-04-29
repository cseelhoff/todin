package game

Offensive_General :: struct {
	using parent: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}
