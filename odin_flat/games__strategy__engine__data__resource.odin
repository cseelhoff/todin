package game

// games.strategy.engine.data.Resource

Resource :: struct {
        using named_attachable: Named_Attachable,
        players: [dynamic]^Game_Player,
}

resource_new :: proc(name: string, data: ^Game_Data, players: []^Game_Player) -> ^Resource {
	self := new(Resource)
	base := named_attachable_new(name, data)
	self.named_attachable = base^
	free(base)
	self.players = make([dynamic]^Game_Player, 0, len(players))
	for p in players {
		append(&self.players, p)
	}
	return self
}

resource_new_simple :: proc(name: string, data: ^Game_Data) -> ^Resource {
	return resource_new(name, data, nil)
}
