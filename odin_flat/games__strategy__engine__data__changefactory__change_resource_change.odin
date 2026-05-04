package game

Change_Resource_Change :: struct {
	using change: Change,
	player_name:   string,
	resource_name: string,
	quantity:      i32,
}

// Java: ChangeResourceChange(GamePlayer player, Resource resource, int quantity)
change_resource_change_new :: proc(player: ^Game_Player, resource: ^Resource, quantity: i32) -> ^Change_Resource_Change {
	self := new(Change_Resource_Change)
	self.change.kind = .Change_Resource_Change
	self.player_name = player.named.base.name
	self.resource_name = resource.named.base.name
	self.quantity = quantity
	return self
}

// Java: ChangeResourceChange#perform(GameState data)
change_resource_change_perform :: proc(self: ^Change_Resource_Change, data: ^Game_State) {
	resource := resource_list_get_resource_or_throw(game_state_get_resource_list(data), self.resource_name)
	player := player_list_get_player_id(game_state_get_player_list(data), self.player_name)
	resources := game_player_get_resources(player)
	if self.quantity > 0 {
		resource_collection_add_resource(resources, resource, self.quantity)
	} else if self.quantity < 0 {
		resource_collection_remove_resource_up_to(resources, resource, -self.quantity)
	}
}
