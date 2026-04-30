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
player_manager_get_played_by :: proc(self: ^Player_Manager, player_node: ^I_Node) -> map[string]struct{} {
	result: map[string]struct{}
	for k, v in self.player_mapping {
		if v == player_node {
			result[k] = {}
		}
	}
	return result
}
player_manager_get_player_mapping :: proc(self: ^Player_Manager) -> map[string]^I_Node {
	result: map[string]^I_Node
	for k, v in self.player_mapping {
		result[k] = v
	}
	return result
}
// Java owners covered by this file:
//   - games.strategy.engine.data.PlayerManager

