package game

Parameters :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	side:           Battle_State_Side,
	bridge:         ^I_Delegate_Bridge,
	units:          [dynamic]^Unit,
}
