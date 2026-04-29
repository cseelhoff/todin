package game

// Ported from org.triplea.map.data.elements.Production$RepairFrontier

Map_Data_Repair_Frontier_Repair_Rules :: struct {
	name: string,
}

Map_Data_Repair_Frontier :: struct {
	name:         string,
	repair_rules: [dynamic]Map_Data_Repair_Frontier_Repair_Rules,
}

