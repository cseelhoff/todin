package game

// games.strategy.engine.data.UnitsList
//
// Game-wide unit registry, keyed by UUID.

Units_List :: struct {
	units: map[Uuid]^Unit,
}
