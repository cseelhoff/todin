package game

Production_Rule_List :: struct {
	using game_data_component: Game_Data_Component,
	production_rules: map[string]^Production_Rule,
}

