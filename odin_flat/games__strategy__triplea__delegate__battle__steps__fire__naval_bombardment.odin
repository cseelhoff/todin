package game

Naval_Bombardment :: struct {
	using battle_step: Battle_Step,
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
}

naval_bombardment_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Naval_Bombardment {
	self := new(Naval_Bombardment)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

naval_bombardment_get_order :: proc(self: ^Naval_Bombardment) -> Battle_Step_Order {
	return .NAVAL_BOMBARDMENT
}
