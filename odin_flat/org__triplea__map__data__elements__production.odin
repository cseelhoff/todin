package game

Map_Data_Production_Rule_Cost :: struct {
	resource: string,
	quantity: ^i32,
}

Map_Data_Production_Rule_Result :: struct {
	resource_or_unit: string,
	quantity:         ^i32,
}

Map_Data_Production_Production_Rule :: struct {
	name:    string,
	costs:   [dynamic]^Map_Data_Production_Rule_Cost,
	results: [dynamic]^Map_Data_Production_Rule_Result,
}

Map_Data_Production_Repair_Rule :: struct {
	name:    string,
	costs:   [dynamic]^Map_Data_Production_Rule_Cost,
	results: [dynamic]^Map_Data_Production_Rule_Result,
}

Map_Data_Production_Repair_Frontier_Repair_Rules :: struct {
	name: string,
}

Map_Data_Production_Repair_Frontier :: struct {
	name:         string,
	repair_rules: [dynamic]^Map_Data_Production_Repair_Frontier_Repair_Rules,
}

Map_Data_Production_Production_Frontier_Frontier_Rules :: struct {
	name: string,
}

Map_Data_Production_Production_Frontier :: struct {
	name:           string,
	frontier_rules: [dynamic]^Map_Data_Production_Production_Frontier_Frontier_Rules,
}

Map_Data_Production_Player_Production :: struct {
	player:   string,
	frontier: string,
}

Map_Data_Production_Player_Repair :: struct {
	player:   string,
	frontier: string,
}

Map_Data_Production :: struct {
	production_rules:     [dynamic]^Map_Data_Production_Production_Rule,
	repair_rules:         [dynamic]^Map_Data_Production_Repair_Rule,
	repair_frontiers:     [dynamic]^Map_Data_Production_Repair_Frontier,
	production_frontiers: [dynamic]^Map_Data_Production_Production_Frontier,
	player_productions:   [dynamic]^Map_Data_Production_Player_Production,
	player_repairs:       [dynamic]^Map_Data_Production_Player_Repair,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Production

