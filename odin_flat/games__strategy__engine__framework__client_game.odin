package game

import "core:fmt"

Client_Game :: struct {
	using abstract_game: Abstract_Game,
}
// Java owners covered by this file:
//   - games.strategy.engine.framework.ClientGame

// games.strategy.engine.framework.ClientGame#getRemoteStepAdvancerName(games.strategy.net.INode)
client_game_get_remote_step_advancer_name :: proc(node: ^I_Node) -> ^Remote_Name {
	player_name := i_node_get_player_name(node)
	name := fmt.aprintf("games.strategy.engine.framework.ClientGame.REMOTE_STEP_ADVANCER:%s", player_name.value)
	return remote_name_new(name, class_new("games.strategy.engine.framework.IGameStepAdvancer", "IGameStepAdvancer"))
}

