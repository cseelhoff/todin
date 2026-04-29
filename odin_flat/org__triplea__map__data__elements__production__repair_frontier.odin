package game

// Ported from org.triplea.map.data.elements.Production$RepairFrontier

Production_Repair_Frontier :: struct {
	name:         string,
	repair_rules: [dynamic]Production_Repair_Frontier_Repair_Rules,
}

