package game

Moderator_Promoted :: struct {
	player_name: string,
}

make_Moderator_Promoted :: proc(player_name: string) -> Moderator_Promoted {
	return Moderator_Promoted{player_name = player_name}
}

moderator_promoted_get_player_name :: proc(self: ^Moderator_Promoted) -> string { return self.player_name }

