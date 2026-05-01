package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.LocalPlayers

Local_Players :: struct {
	local_players: [dynamic]^Player,
}

make_Local_Players :: proc(local_player_types: [dynamic]^Player) -> Local_Players {
	return Local_Players{local_players = local_player_types}
}

// games.strategy.engine.framework.LocalPlayers#isGamePlayerWithPlayerId(
//   games.strategy.engine.player.Player, games.strategy.engine.data.GamePlayer)
local_players_is_game_player_with_player_id :: proc(player: ^Player, game_player: ^Game_Player) -> bool {
	return player_get_game_player(player) == game_player && !player_is_ai(player)
}

