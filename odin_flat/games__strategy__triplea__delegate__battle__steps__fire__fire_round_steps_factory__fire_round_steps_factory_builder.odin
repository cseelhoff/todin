package game

Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder :: struct {
	battle_state:          ^Battle_State,
	battle_actions:        ^Battle_Actions,
	firing_group_splitter: proc(^Battle_State) -> [dynamic]^Firing_Group,
	side:                  ^Battle_State_Side,
	return_fire:           ^Must_Fight_Battle_Return_Fire,
	dice_roller:           proc(^I_Delegate_Bridge, ^Roll_Dice_Step) -> ^Dice_Roll,
	casualty_selector:     proc(^I_Delegate_Bridge, ^Select_Casualties) -> ^Casualty_Details,
}

fire_round_steps_factory_builder_new :: proc() -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	return new(Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder)
}

fire_round_steps_factory_builder_battle_state :: proc(self: ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder, battle_state: ^Battle_State) -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	self.battle_state = battle_state
	return self
}

fire_round_steps_factory_builder_battle_actions :: proc(self: ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder, battle_actions: ^Battle_Actions) -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	self.battle_actions = battle_actions
	return self
}

fire_round_steps_factory_builder_firing_group_splitter :: proc(self: ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder, firing_group_splitter: proc(^Battle_State) -> [dynamic]^Firing_Group) -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	self.firing_group_splitter = firing_group_splitter
	return self
}

fire_round_steps_factory_builder_side :: proc(self: ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder, side: ^Battle_State_Side) -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	self.side = side
	return self
}

fire_round_steps_factory_builder_return_fire :: proc(self: ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder, return_fire: ^Must_Fight_Battle_Return_Fire) -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	self.return_fire = return_fire
	return self
}

fire_round_steps_factory_builder_dice_roller :: proc(self: ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder, dice_roller: proc(^I_Delegate_Bridge, ^Roll_Dice_Step) -> ^Dice_Roll) -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	self.dice_roller = dice_roller
	return self
}

fire_round_steps_factory_builder_casualty_selector :: proc(self: ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder, casualty_selector: proc(^I_Delegate_Bridge, ^Select_Casualties) -> ^Casualty_Details) -> ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder {
	self.casualty_selector = casualty_selector
	return self
}

// Lombok @Builder build(): construct a Fire_Round_Steps_Factory from the
// accumulated builder fields. The builder stores the enum-typed `side`
// and `return_fire` fields as pointers so that "unset" can be modeled
// as nil; build() dereferences them (defaulting to the zero enum value
// when nil, matching Java's null-tolerated returnFire field).
fire_round_steps_factory_builder_build :: proc(self: ^Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder) -> ^Fire_Round_Steps_Factory {
	side_val: Battle_State_Side
	if self.side != nil {
		side_val = self.side^
	}
	return_fire_val: Must_Fight_Battle_Return_Fire
	if self.return_fire != nil {
		return_fire_val = self.return_fire^
	}
	return fire_round_steps_factory_new(
		self.battle_state,
		self.battle_actions,
		self.firing_group_splitter,
		side_val,
		return_fire_val,
		self.dice_roller,
		self.casualty_selector,
	)
}
