package game

Evader_Retreat_Parameters_Parameters_Builder :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	side:           Battle_State_Side,
	bridge:         ^I_Delegate_Bridge,
	units:          [dynamic]^Unit,
}

evader_retreat_parameters_parameters_builder_new :: proc() -> ^Evader_Retreat_Parameters_Parameters_Builder {
	self := new(Evader_Retreat_Parameters_Parameters_Builder)
	return self
}

evader_retreat_parameters_parameters_builder_battle_state :: proc(self: ^Evader_Retreat_Parameters_Parameters_Builder, battle_state: ^Battle_State) -> ^Evader_Retreat_Parameters_Parameters_Builder {
	self.battle_state = battle_state
	return self
}

evader_retreat_parameters_parameters_builder_battle_actions :: proc(self: ^Evader_Retreat_Parameters_Parameters_Builder, battle_actions: ^Battle_Actions) -> ^Evader_Retreat_Parameters_Parameters_Builder {
	self.battle_actions = battle_actions
	return self
}

evader_retreat_parameters_parameters_builder_side :: proc(self: ^Evader_Retreat_Parameters_Parameters_Builder, side: Battle_State_Side) -> ^Evader_Retreat_Parameters_Parameters_Builder {
	self.side = side
	return self
}

evader_retreat_parameters_parameters_builder_bridge :: proc(self: ^Evader_Retreat_Parameters_Parameters_Builder, bridge: ^I_Delegate_Bridge) -> ^Evader_Retreat_Parameters_Parameters_Builder {
	self.bridge = bridge
	return self
}

evader_retreat_parameters_parameters_builder_units :: proc(self: ^Evader_Retreat_Parameters_Parameters_Builder, units: [dynamic]^Unit) -> ^Evader_Retreat_Parameters_Parameters_Builder {
	self.units = units
	return self
}

evader_retreat_parameters_parameters_builder_build :: proc(self: ^Evader_Retreat_Parameters_Parameters_Builder) -> ^Evader_Retreat_Parameters {
	return evader_retreat_parameters_new(
		self.battle_state,
		self.battle_actions,
		self.side,
		self.bridge,
		self.units,
	)
}

