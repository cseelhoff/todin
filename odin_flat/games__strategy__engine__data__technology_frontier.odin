package game

Technology_Frontier :: struct {
	using game_data_component: Game_Data_Component,
	techs: [dynamic]^Tech_Advance,
	name:  string,
}

technology_frontier_get_techs :: proc(self: ^Technology_Frontier) -> [dynamic]^Tech_Advance {
	return self.techs
}

technology_frontier_is_empty :: proc(self: ^Technology_Frontier) -> bool {
	return len(self.techs) == 0
}

// Java: TechnologyFrontier#iterator() — returns getTechs().iterator().
// Odin convention (see production_frontier_iterator, game_map_iterator):
// expose the backing list and let callers `for t in technology_frontier_iterator(tf)`.
technology_frontier_iterator :: proc(self: ^Technology_Frontier) -> [dynamic]^Tech_Advance {
	return technology_frontier_get_techs(self)
}
