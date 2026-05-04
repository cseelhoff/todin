package game

Pro_Purchase_Option_Map :: struct {
	land_fodder_options:    [dynamic]^Pro_Purchase_Option,
	land_attack_options:    [dynamic]^Pro_Purchase_Option,
	land_defense_options:   [dynamic]^Pro_Purchase_Option,
	land_zero_move_options: [dynamic]^Pro_Purchase_Option,
	air_options:            [dynamic]^Pro_Purchase_Option,
	sea_defense_options:    [dynamic]^Pro_Purchase_Option,
	sea_transport_options:  [dynamic]^Pro_Purchase_Option,
	sea_carrier_options:    [dynamic]^Pro_Purchase_Option,
	sea_sub_options:        [dynamic]^Pro_Purchase_Option,
	aa_options:             [dynamic]^Pro_Purchase_Option,
	factory_options:        [dynamic]^Pro_Purchase_Option,
	special_options:        [dynamic]^Pro_Purchase_Option,
}
// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.data.ProPurchaseOptionMap

pro_purchase_option_map_get_land_fodder_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.land_fodder_options
}

pro_purchase_option_map_get_land_attack_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.land_attack_options
}

pro_purchase_option_map_get_land_defense_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.land_defense_options
}

pro_purchase_option_map_get_land_zero_move_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.land_zero_move_options
}

pro_purchase_option_map_get_air_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.air_options
}

pro_purchase_option_map_get_sea_defense_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.sea_defense_options
}

pro_purchase_option_map_get_sea_transport_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.sea_transport_options
}

pro_purchase_option_map_get_aa_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.aa_options
}

pro_purchase_option_map_get_factory_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.factory_options
}

pro_purchase_option_map_get_land_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	seen: map[^Pro_Purchase_Option]struct{}
	defer delete(seen)
	result: [dynamic]^Pro_Purchase_Option
	for ppo in self.land_fodder_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.land_attack_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.land_defense_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	return result
}

pro_purchase_option_map_get_sea_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	seen: map[^Pro_Purchase_Option]struct{}
	defer delete(seen)
	result: [dynamic]^Pro_Purchase_Option
	for ppo in self.sea_defense_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.sea_transport_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.sea_carrier_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.sea_sub_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	return result
}

pro_purchase_option_map_can_unit_type_suicide :: proc(self: ^Pro_Purchase_Option_Map, unit_type: ^Unit_Type, player: ^Game_Player) -> bool {
	ua := unit_type_get_unit_attachment(unit_type)
	return (unit_attachment_get_is_suicide_on_attack(ua) &&
			unit_attachment_get_movement_with_player(ua, player) > 0) ||
		unit_attachment_get_is_suicide_on_defense(ua)
}

