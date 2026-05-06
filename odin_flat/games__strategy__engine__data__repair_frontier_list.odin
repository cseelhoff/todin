package game

Repair_Frontier_List :: struct {
	using game_data_component: Game_Data_Component,
	repair_frontiers: map[string]^Repair_Frontier,
}

repair_frontier_list_new :: proc(data: ^Game_Data) -> ^Repair_Frontier_List {
	self := new(Repair_Frontier_List)
	self.game_data_component = make_Game_Data_Component(data)
	self.repair_frontiers = make(map[string]^Repair_Frontier)
	return self
}

repair_frontier_list_add_repair_frontier :: proc(self: ^Repair_Frontier_List, pf: ^Repair_Frontier) {
	self.repair_frontiers[pf.default_named.named.base.name] = pf
}

repair_frontier_list_get_repair_frontier :: proc(self: ^Repair_Frontier_List, name: string) -> ^Repair_Frontier {
	return self.repair_frontiers[name]
}


// games.strategy.engine.data.RepairFrontierList#getRepairFrontierNames()
// Java body: return repairFrontiers.keySet();
repair_frontier_list_get_repair_frontier_names :: proc(self: ^Repair_Frontier_List) -> [dynamic]string {
	out := make([dynamic]string, 0, len(self.repair_frontiers))
	for name, _ in self.repair_frontiers {
		append(&out, name)
	}
	return out
}
