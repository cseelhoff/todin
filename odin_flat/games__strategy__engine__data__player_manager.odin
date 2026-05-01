package game

import "core:fmt"
import "core:strings"

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
player_manager_lambda_get_played_by_1 :: proc(node: ^I_Node, entry_key: string, entry_value: ^I_Node) -> bool {
	return entry_value == node
}

player_manager_lambda_get_remote_opponent_2 :: proc(node: ^I_Node, entry_key: string, entry_value: ^I_Node) -> bool {
	return entry_value == node
}

player_manager_is_playing :: proc(self: ^Player_Manager, node: ^I_Node) -> bool {
	for _, v in self.player_mapping {
		if v == node {
			return true
		}
	}
	return false
}

player_manager_is_empty :: proc(self: ^Player_Manager) -> bool {
	return len(self.player_mapping) == 0
}

// games.strategy.engine.data.PlayerManager#toString()
//
// Java:
//   if (playerMapping.isEmpty()) return "empty";
//   return playerMapping.entrySet().stream()
//       .map(e -> String.format("%s=%s", e.getKey(), e.getValue().getName()))
//       .collect(Collectors.joining(", "));
//
// I_Node is an empty marker in the Odin port; the only implementer is Node,
// which embeds I_Node at offset 0 via `using i_node: I_Node`. The downcast
// (^Node)(v) therefore reads Node.name at the same address.
player_manager_to_string :: proc(self: ^Player_Manager) -> string {
	if len(self.player_mapping) == 0 {
		return "empty"
	}
	parts: [dynamic]string
	defer {
		for s in parts {
			delete(s)
		}
		delete(parts)
	}
	for k, v in self.player_mapping {
		append(&parts, fmt.aprintf("%s=%s", k, (^Node)(v).name))
	}
	return strings.join(parts[:], ", ")
}

// games.strategy.engine.data.PlayerManager#lambda$toString$0(Map.Entry)
//
// Java: e -> String.format("%s=%s", e.getKey(), e.getValue().getName())
player_manager_lambda_to_string_0 :: proc(entry_key: string, entry_value: ^I_Node) -> string {
	return fmt.aprintf("%s=%s", entry_key, (^Node)(entry_value).name)
}

// Java owners covered by this file:
//   - games.strategy.engine.data.PlayerManager

