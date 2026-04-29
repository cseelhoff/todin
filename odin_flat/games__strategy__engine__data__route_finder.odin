package game

Route_Finder :: struct {
	move_validator: ^Move_Validator,
	game_map:       ^Game_Map,
	condition:      proc(t: ^Territory) -> bool,
	units:          [dynamic]^Unit,
	player:         ^Game_Player,
}

