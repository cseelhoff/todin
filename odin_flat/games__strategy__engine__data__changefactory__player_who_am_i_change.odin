package game

Player_Who_Am_I_Change :: struct {
	using change: Change,
	start_who_am_i: string,
	end_who_am_i:   string,
	player_name:    string,
}

player_who_am_i_change_new :: proc(new_who_am_i: string, player: ^Game_Player) -> ^Player_Who_Am_I_Change {
	self := new(Player_Who_Am_I_Change)
	self.start_who_am_i = game_player_get_who_am_i(player)
	self.end_who_am_i = new_who_am_i
	self.player_name = default_named_get_name(&player.named_attachable.default_named)
	return self
}

