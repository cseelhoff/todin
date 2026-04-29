package game

Map_Data_Production_Frontier_Frontier_Rules :: struct {
	name: string,
}

Map_Data_Production_Frontier :: struct {
	name:           string,
	frontier_rules: [dynamic]^Map_Data_Production_Frontier_Frontier_Rules,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Production$ProductionFrontier

