package game

Player_Manager :: struct {
	player_mapping: map[string]^I_Node,
}

make_Player_Manager :: proc(player_mapping: map[string]^I_Node) -> Player_Manager {
	copy_map: map[string]^I_Node
	for k, v in player_mapping {
		copy_map[k] = v
	}
	return Player_Manager{player_mapping = copy_map}
}

player_manager_get_players :: proc(self: ^Player_Manager) -> map[string]struct{} {
	result: map[string]struct{}
	for k, _ in self.player_mapping {
		result[k] = {}
	}
	return result
}
player_manager_get_node :: proc(self: ^Player_Manager, name: string) -> ^I_Node {
	return self.player_mapping[name]
}
// Java owners covered by this file:
//   - games.strategy.engine.data.PlayerManager

