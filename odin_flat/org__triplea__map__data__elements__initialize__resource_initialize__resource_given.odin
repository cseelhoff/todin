package game

Initialize_Resource_Initialize_Resource_Given :: struct {
	player:   string,
	resource: string,
	quantity: i32,
}

initialize_resource_initialize_resource_given_get_player :: proc(self: ^Initialize_Resource_Initialize_Resource_Given) -> string {
	return self.player
}

initialize_resource_initialize_resource_given_get_resource :: proc(self: ^Initialize_Resource_Initialize_Resource_Given) -> string {
	return self.resource
}

initialize_resource_initialize_resource_given_get_quantity :: proc(self: ^Initialize_Resource_Initialize_Resource_Given) -> i32 {
	return self.quantity
}
