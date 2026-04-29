package game

// games.strategy.engine.data.ResourceList

Resource_List :: struct {
	using game_data_component: Game_Data_Component,
	resources: map[string]^Resource,
}
