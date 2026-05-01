package game

Evader_Retreat_Parameters :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	side:           Battle_State_Side,
	bridge:         ^I_Delegate_Bridge,
	units:          [dynamic]^Unit,
}

evader_retreat_parameters_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
	side: Battle_State_Side,
	bridge: ^I_Delegate_Bridge,
	units: [dynamic]^Unit,
) -> ^Evader_Retreat_Parameters {
	p := new(Evader_Retreat_Parameters)
	p.battle_state = battle_state
	p.battle_actions = battle_actions
	p.side = side
	p.bridge = bridge
	p.units = units
	return p
}

evader_retreat_parameters_builder :: proc() -> ^Evader_Retreat_Parameters_Parameters_Builder {
	return evader_retreat_parameters_parameters_builder_new()
}
