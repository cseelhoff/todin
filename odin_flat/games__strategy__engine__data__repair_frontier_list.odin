package game

Repair_Frontier_List :: struct {
	using game_data_component: Game_Data_Component,
	repair_frontiers: map[string]^Repair_Frontier,
}

repair_frontier_list_add_repair_frontier :: proc(self: ^Repair_Frontier_List, pf: ^Repair_Frontier) {
	self.repair_frontiers[pf.default_named.named.base.name] = pf
}

repair_frontier_list_get_repair_frontier :: proc(self: ^Repair_Frontier_List, name: string) -> ^Repair_Frontier {
	return self.repair_frontiers[name]
}

