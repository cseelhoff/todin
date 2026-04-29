package game

Repair_Rules :: struct {
	using game_data_component: Game_Data_Component,
	repair_rules:              map[string]^Repair_Rule,
}

