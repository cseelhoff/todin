package game

Pro_Territory :: struct {
	pro_data:                ^Pro_Data,
	territory:               ^Territory,
	max_units:               map[^Unit]struct{},
	units:                   [dynamic]^Unit,
	bombers:                 [dynamic]^Unit,
	max_battle_result:       ^Pro_Battle_Result,
	value:                   f64,
	sea_value:               f64,
	can_hold:                bool,
	can_attack:              bool,
	strength_estimate:       f64,

	// Amphib variables
	max_amphib_units:        [dynamic]^Unit,
	amphib_attack_map:       map[^Unit][dynamic]^Unit,
	transport_territory_map: map[^Unit]^Territory,
	need_amphib_units:       bool,
	strafing:                bool,
	is_transporting_map:     map[^Unit]bool,
	max_bombard_units:       map[^Unit]struct{},
	bombard_options_map:     map[^Unit]map[^Territory]struct{},
	bombard_territory_map:   map[^Unit]^Territory,

	// Determine territory to attack variables
	currently_wins:          bool,
	battle_result:           ^Pro_Battle_Result,

	// Non-combat move variables
	cant_move_units:         map[^Unit]struct{},
	max_enemy_units:         [dynamic]^Unit,
	max_enemy_bombard_units: map[^Unit]struct{},
	min_battle_result:       ^Pro_Battle_Result,
	temp_units:              [dynamic]^Unit,
	temp_amphib_attack_map:  map[^Unit][dynamic]^Unit,
	load_value:              f64,

	// Scramble variables
	max_scramble_units:      [dynamic]^Unit,
}

