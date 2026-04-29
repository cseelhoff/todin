package game

// Ported from org.triplea.map.data.elements.Production$ProductionFrontier

Production_Production_Frontier :: struct {
	name:           string,
	frontier_rules: [dynamic]^Production_Production_Frontier_Frontier_Rules,
}

