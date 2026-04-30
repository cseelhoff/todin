package game

Technology_Frontier_List :: struct {
	using game_data_component: Game_Data_Component,
	technology_frontiers: [dynamic]^Technology_Frontier,
}

technology_frontier_list_add_technology_frontier :: proc(self: ^Technology_Frontier_List, tf: ^Technology_Frontier) {
	append(&self.technology_frontiers, tf)
}

