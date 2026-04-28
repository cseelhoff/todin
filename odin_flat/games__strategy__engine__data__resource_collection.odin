package game

// games.strategy.engine.data.ResourceCollection
//
// Per-player wallet: Resource → quantity.

Integer_Map_Resource :: map[^Resource]i32

Resource_Collection :: struct {
	resources: Integer_Map_Resource,
}
