package game

Player_Bridge :: struct {
	game:             ^IGame,
	step_name:        string,
	current_delegate: string,
}

player_bridge_get_step_name :: proc(self: ^Player_Bridge) -> string {
	return self.step_name
}
