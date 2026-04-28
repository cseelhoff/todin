package game

// games.strategy.engine.data.GameMap
//
// Holds every territory plus a name-keyed lookup.

Game_Map :: struct {
	territories:       [dynamic]^Territory,
	territory_lookup:  map[string]^Territory,
}
