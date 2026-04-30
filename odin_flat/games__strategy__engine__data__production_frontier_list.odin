package game

Production_Frontier_List :: struct {
	using game_data_component: Game_Data_Component,
	production_frontiers:      map[string]^Production_Frontier,
}

production_frontier_list_add_production_frontier :: proc(self: ^Production_Frontier_List, pf: ^Production_Frontier) {
	self.production_frontiers[pf.default_named.named.base.name] = pf
}

production_frontier_list_get_production_frontier :: proc(self: ^Production_Frontier_List, name: string) -> ^Production_Frontier {
	return self.production_frontiers[name]
}
