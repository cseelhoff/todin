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
