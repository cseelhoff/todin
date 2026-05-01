package game

import "core:fmt"

Technology_Frontier_List :: struct {
	using game_data_component: Game_Data_Component,
	technology_frontiers: [dynamic]^Technology_Frontier,
}

technology_frontier_list_new :: proc(data: ^Game_Data) -> ^Technology_Frontier_List {
	self := new(Technology_Frontier_List)
	self.game_data_component = make_Game_Data_Component(data)
	self.technology_frontiers = make([dynamic]^Technology_Frontier)
	return self
}

technology_frontier_list_add_technology_frontier :: proc(self: ^Technology_Frontier_List, tf: ^Technology_Frontier) {
	append(&self.technology_frontiers, tf)
}

technology_frontier_list_get_frontiers :: proc(self: ^Technology_Frontier_List) -> []^Technology_Frontier {
	return self.technology_frontiers[:]
}

technology_frontier_list_get_advances :: proc(self: ^Technology_Frontier_List) -> [dynamic]^Tech_Advance {
	techs := make([dynamic]^Tech_Advance)
	for t in self.technology_frontiers {
		inner := technology_frontier_get_techs(t)
		for adv in inner {
			append(&techs, adv)
		}
	}
	return techs
}

technology_frontier_list_get_technology_frontier_or_throw :: proc(player: ^Game_Player, name: string) -> ^Technology_Frontier {
	list := game_player_get_technology_frontier_list(player)
	for tf in list.technology_frontiers {
		if technology_frontier_get_name(tf) == name {
			return tf
		}
	}
	panic(fmt.aprintf("TechnologyFrontier doesn't exist: %s for player: %s", name, game_player_to_string(player)))
}

