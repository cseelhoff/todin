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

