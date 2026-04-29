package game

Production_Frontier_List :: struct {
	using game_data_component: Game_Data_Component,
	production_frontiers:      map[string]^Production_Frontier,
}
