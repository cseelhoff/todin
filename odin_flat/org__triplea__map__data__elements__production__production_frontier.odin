package game

// Ported from org.triplea.map.data.elements.Production$ProductionFrontier

Production_Production_Frontier :: struct {
	name:           string,
	frontier_rules: [dynamic]^Production_Production_Frontier_Frontier_Rules,
}

production_production_frontier_get_name :: proc(self: ^Production_Production_Frontier) -> string {
	return self.name
}

production_production_frontier_get_frontier_rules :: proc(self: ^Production_Production_Frontier) -> [dynamic]^Production_Production_Frontier_Frontier_Rules {
	return self.frontier_rules
}

