package game

// Ported from org.triplea.map.data.elements.Production$RepairFrontier

Production_Repair_Frontier :: struct {
	name:         string,
	repair_rules: [dynamic]Production_Repair_Frontier_Repair_Rules,
}

production_repair_frontier_get_name :: proc(self: ^Production_Repair_Frontier) -> string {
	return self.name
}

production_repair_frontier_get_repair_rules :: proc(self: ^Production_Repair_Frontier) -> [dynamic]Production_Repair_Frontier_Repair_Rules {
	return self.repair_rules
}

