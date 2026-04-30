package game

// Java owner: games.strategy.triplea.ai.pro.ProData

Pro_Data :: struct {
	is_simulation:          bool,
	win_percentage:         f64,
	min_win_percentage:     f64,
	my_capital:             ^Territory,
	my_unit_territories:    [dynamic]^Territory,
	unit_territory_map:     map[^Unit]^Territory,
	unit_value_map:         map[^Unit_Type]i32,
	purchase_options:       ^Pro_Purchase_Option_Map,
	units_to_be_consumed:   map[^Unit]struct {},
	min_cost_per_hit_point: f64,
	pro_ai:                 ^Abstract_Pro_Ai,
	data:                   ^Game_Data,
	player:                 ^Game_Player,
}

pro_data_get_my_capital :: proc(self: ^Pro_Data) -> ^Territory {
	return self.my_capital
}


pro_data_get_data :: proc(self: ^Pro_Data) -> ^Game_Data {
	return self.data
}


pro_data_get_pro_ai :: proc(self: ^Pro_Data) -> ^Abstract_Pro_Ai {
	return self.pro_ai
}

pro_data_get_min_cost_per_hit_point :: proc(self: ^Pro_Data) -> f64 {
	return self.min_cost_per_hit_point
}


pro_data_get_player :: proc(self: ^Pro_Data) -> ^Game_Player {
	return self.player
}


pro_data_get_my_unit_territories :: proc(self: ^Pro_Data) -> [dynamic]^Territory {
	return self.my_unit_territories
}


pro_data_get_pro_territory :: proc(self: ^Pro_Data, move_map: map[^Territory]^Pro_Territory, t: ^Territory) -> ^Pro_Territory {
	move_map := move_map
	if existing, ok := move_map[t]; ok {
		return existing
	}
	created := pro_territory_new(t, self)
	move_map[t] = created
	return created
}


pro_data_get_units_to_be_consumed :: proc(self: ^Pro_Data) -> map[^Unit]struct {} {
	return self.units_to_be_consumed
}


pro_data_get_unit_territory_map :: proc(self: ^Pro_Data) -> map[^Unit]^Territory {
	return self.unit_territory_map
}

pro_data_is_simulation :: proc(self: ^Pro_Data) -> bool {
	return self.is_simulation
}


pro_data_get_purchase_options :: proc(self: ^Pro_Data) -> ^Pro_Purchase_Option_Map {
	return self.purchase_options
}


pro_data_get_unit_value_map :: proc(self: ^Pro_Data) -> map[^Unit_Type]i32 {
	return self.unit_value_map
}


pro_data_get_unit_territory :: proc(self: ^Pro_Data, unit: ^Unit) -> ^Territory {
	if t, ok := self.unit_territory_map[unit]; ok {
		return t
	}
	return nil
}


pro_data_get_win_percentage :: proc(self: ^Pro_Data) -> f64 {
	return self.win_percentage
}
