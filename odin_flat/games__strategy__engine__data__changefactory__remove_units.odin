package game

Remove_Units :: struct {
	using parent: Change,
	name:           string,
	units:          [dynamic]^Unit,
	type:           string,
	unit_owner_map: map[Uuid]string,
}
// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.RemoveUnits

