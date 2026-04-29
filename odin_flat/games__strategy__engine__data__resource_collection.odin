package game

// games.strategy.engine.data.ResourceCollection
//
// Per-player wallet: Resource → quantity.

Integer_Map_Resource :: map[^Resource]i32

Resource_Collection :: struct {
	using game_data_component: Game_Data_Component,
	resources: Integer_Map_Resource,
}
