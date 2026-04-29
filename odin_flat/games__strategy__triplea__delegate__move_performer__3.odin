package game

Move_Performer_3 :: struct {
	using parent: I_Executable,
	outer: ^Move_Performer,
	game_player: ^Game_Player,
	units: [dynamic]^Unit,
	route: ^Route,
	units_to_transports: map[^Unit]^Unit,
}

