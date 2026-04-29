package game

Repair_Rule :: struct {
	using parent: Default_Named,
	using rule:   Rule,
	costs:        ^Integer_Map,
	results:      ^Integer_Map,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.RepairRule

