package game

Production_Frontier_List :: struct {
	using game_data_component: Game_Data_Component,
	production_frontiers:      map[string]^Production_Frontier,
}

production_frontier_list_new :: proc(data: ^Game_Data) -> ^Production_Frontier_List {
	self := new(Production_Frontier_List)
	self.game_data_component = make_Game_Data_Component(data)
	self.production_frontiers = make(map[string]^Production_Frontier)
	return self
}

production_frontier_list_add_production_frontier :: proc(self: ^Production_Frontier_List, pf: ^Production_Frontier) {
	self.production_frontiers[pf.default_named.named.base.name] = pf
}

production_frontier_list_get_production_frontier :: proc(self: ^Production_Frontier_List, name: string) -> ^Production_Frontier {
	return self.production_frontiers[name]
}

// games.strategy.engine.data.ProductionFrontierList#getProductionFrontierNames()
// Java body: return productionFrontiers.keySet();
production_frontier_list_get_production_frontier_names :: proc(self: ^Production_Frontier_List) -> [dynamic]string {
	out := make([dynamic]string, 0, len(self.production_frontiers))
	for name, _ in self.production_frontiers {
		append(&out, name)
	}
	return out
}
