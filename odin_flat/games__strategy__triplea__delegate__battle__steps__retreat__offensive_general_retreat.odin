package game

import "core:fmt"

Offensive_General_Retreat :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

offensive_general_retreat_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Offensive_General_Retreat {
	self := new(Offensive_General_Retreat)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

offensive_general_retreat_get_order :: proc(self: ^Offensive_General_Retreat) -> Battle_Step_Order {
	return Battle_Step_Order.OFFENSIVE_GENERAL_RETREAT
}

offensive_general_retreat_get_short_broadcast_suffix :: proc(self: ^Offensive_General_Retreat, retreat_type: Must_Fight_Battle_Retreat_Type) -> string {
	switch retreat_type {
	case .PARTIAL_AMPHIB:
		return " retreats non-amphibious units"
	case .PLANES:
		return " retreats planes"
	case .DEFAULT, .SUBS:
		return " retreats"
	}
	return " retreats"
}

offensive_general_retreat_get_long_broadcast_suffix :: proc(self: ^Offensive_General_Retreat, retreat_type: Must_Fight_Battle_Retreat_Type, retreat_to: ^Territory) -> string {
	switch retreat_type {
	case .PARTIAL_AMPHIB:
		return " retreats non-amphibious units"
	case .PLANES:
		return " retreats planes"
	case .DEFAULT, .SUBS:
		name := default_named_get_name(&retreat_to.named_attachable.default_named)
		return fmt.aprintf(" retreats all units to %s", name)
	}
	return ""
}

