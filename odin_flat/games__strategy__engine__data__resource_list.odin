package game

import "core:fmt"

// games.strategy.engine.data.ResourceList

Resource_List :: struct {
	using game_data_component: Game_Data_Component,
	resources: map[string]^Resource,
}

// Java: public void addResource(final Resource resource)
resource_list_add_resource :: proc(self: ^Resource_List, resource: ^Resource) {
	self.resources[default_named_get_name(&resource.named_attachable.default_named)] = resource
}

r

// Java: public Resource getResourceOrThrow(final @NonNls String name)
resource_list_get_resource_or_throw :: proc(self: ^Resource_List, name: string) -> ^Resource {
	resource := resource_list_get_resource_optional(self, name)
	if resource == nil {
		panic(fmt.tprintf("No resource named: %s", name))
	}
	return resource
}esource_list_get_resource_optional :: proc(self: ^Resource_List, name: string) -> ^Resource {
	return self.resources[name]
}
