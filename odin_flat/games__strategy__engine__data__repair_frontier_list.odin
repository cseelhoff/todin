package game

Repair_Frontier_List :: struct {
	using game_data_component: Game_Data_Component,
	repair_frontiers: map[string]^Repair_Frontier,
}

