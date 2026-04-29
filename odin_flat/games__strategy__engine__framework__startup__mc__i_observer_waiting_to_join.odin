package game

I_Observer_Waiting_To_Join :: struct {
	using i_remote: I_Remote,
	join_game:        proc(self: ^I_Observer_Waiting_To_Join, game_data: [dynamic]u8, players: map[string]^I_Node),
	cannot_join_game: proc(self: ^I_Observer_Waiting_To_Join, reason: string),
}

