package game

// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.RemoveBattleRecordsChange

Remove_Battle_Records_Change :: struct {
	using base:        Change,
	records_to_remove: ^Battle_Records,
	round:             int,
}
