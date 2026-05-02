package game

Triple_A :: struct {
	using i_game_loader: I_Game_Loader,
	game: ^I_Game,
}

// Java owners covered by this file:
//   - games.strategy.triplea.TripleA

triple_a_new :: proc() -> ^Triple_A {
	self := new(Triple_A)
	self.game = nil
	return self
}

// Java static: TripleA#toGamePlayer(Map.Entry<String, PlayerTypes.Type>).
// No Map_Entry shim exists in odin_flat/; per the convention used in
// player_listing.odin, the entry is decomposed into its (key, value) pair
// at the call site and passed in directly.
triple_a_to_game_player :: proc(name: string, type: ^Player_Types_Type) -> ^Player {
	return player_types_type_new_player_with_name(type, name)
}

triple_a_new_players :: proc(self: ^Triple_A, player_names: map[string]^Player_Types_Type) -> map[^Player]struct{} {
	result: map[^Player]struct{}
	for name, type in player_names {
		player := player_types_type_new_player_with_name(type, name)
		result[player] = struct{}{}
	}
	return result
}
