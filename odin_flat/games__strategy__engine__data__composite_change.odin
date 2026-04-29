package game

Composite_Change :: struct {
	using parent: Change,
	changes:      [dynamic]^Change,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.CompositeChange

