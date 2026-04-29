package game

Evader_Retreat_Parameters_Parameters_Builder :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	side:           Battle_State_Side,
	bridge:         ^I_Delegate_Bridge,
	units:          [dynamic]^Unit,
}

