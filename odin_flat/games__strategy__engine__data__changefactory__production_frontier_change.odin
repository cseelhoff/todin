package game

Production_Frontier_Change :: struct {
	using change:        Change,
	start_frontier_name: string,
	end_frontier_name:   string,
	player_name:         string,
}

// Java: ProductionFrontierChange(ProductionFrontier newFrontier, GamePlayer player)
production_frontier_change_new :: proc(new_frontier: ^Production_Frontier, player: ^Game_Player) -> ^Production_Frontier_Change {
	self := new(Production_Frontier_Change)
	self.start_frontier_name = named_get_name(&player.production_frontier.default_named.named)
	self.end_frontier_name = named_get_name(&new_frontier.default_named.named)
	self.player_name = named_get_name(&player.named_attachable.default_named.named)
	return self
}

