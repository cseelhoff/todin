package game

// games.strategy.engine.data.UnitCollection
//
// Per-territory bag of units; back-pointer to the holding territory.

Unit_Collection :: struct {
	units:  [dynamic]^Unit,
	holder: ^Territory,
}
