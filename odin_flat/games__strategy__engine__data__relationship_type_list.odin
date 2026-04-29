package game

// games.strategy.engine.data.RelationshipTypeList

Relationship_Type_List :: struct {
	using game_data_component: Game_Data_Component,
	relationship_types: map[string]^Relationship_Type,
}
