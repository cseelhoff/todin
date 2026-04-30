package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.LocalPlayers

Local_Players :: struct {
	local_players: [dynamic]^Player,
}

make_Local_Players :: proc(local_player_types: [dynamic]^Player) -> Local_Players {
	return Local_Players{local_players = local_player_types}
}

