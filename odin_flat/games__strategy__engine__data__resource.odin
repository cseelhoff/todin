package game

// games.strategy.engine.data.Resource

Resource :: struct {
	using parent: Named_Attachable,
	players: [dynamic]^Game_Player,
}
