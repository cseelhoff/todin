package game

I_Game_Step_Advancer :: struct {
	using i_remote: I_Remote,
	start_player_step: proc(self: ^I_Game_Step_Advancer, step_name: string, player: ^Game_Player),
}

i_game_step_advancer_start_player_step :: proc(self: ^I_Game_Step_Advancer, step_name: string, player: ^Game_Player) {
	if self != nil && self.start_player_step != nil {
		self.start_player_step(self, step_name, player)
	}
}

