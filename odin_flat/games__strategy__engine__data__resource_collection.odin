package game

import "core:fmt"

// games.strategy.engine.data.ResourceCollection
//
// Per-player wallet: Resource → quantity.

Integer_Map_Resource :: map[^Resource]i32

Resource_Collection :: struct {
	using game_data_component: Game_Data_Component,
	resources: Integer_Map_Resource,
}

resource_collection_remove_resource_up_to :: proc(self: ^Resource_Collection, resource: ^Resource, quantity: i32) {
	if quantity < 0 {
		panic("quantity must be positive")
	}
	current := resource_collection_get_quantity(self, resource)
	resource_collection_change(self, resource, -min(current, quantity))
}

resource_collection_get_resources_copy :: proc(self: ^Resource_Collection) -> Integer_Map_Resource {
	copy_map: Integer_Map_Resource = make(Integer_Map_Resource)
	for k, v in self.resources {
		copy_map[k] = v
	}
	return copy_map
}

resource_collection_add_resource :: proc(self: ^Resource_Collection, resource: ^Resource, quantity: i32) {
	if quantity < 0 {
		fmt.panicf("quantity must be positive")
	}
	resource_collection_change(self, resource, quantity)
}
