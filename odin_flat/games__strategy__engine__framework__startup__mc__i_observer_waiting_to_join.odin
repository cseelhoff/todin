package game

I_Observer_Waiting_To_Join :: struct {
	cannot_join_game: proc(self: ^I_Observer_Waiting_To_Join, reason: string),
	join_game:        proc(self: ^I_Observer_Waiting_To_Join, game_data: []u8, players_to_node: map[string]^I_Node),
}

i_observer_waiting_to_join_cannot_join_game :: proc(self: ^I_Observer_Waiting_To_Join, reason: string) {
	if self != nil && self.cannot_join_game != nil {
		self.cannot_join_game(self, reason)
	}
}

i_observer_waiting_to_join_join_game :: proc(self: ^I_Observer_Waiting_To_Join, game_data: []u8, players_to_node: map[string]^I_Node) {
	if self != nil && self.join_game != nil {
		self.join_game(self, game_data, players_to_node)
	}
}

