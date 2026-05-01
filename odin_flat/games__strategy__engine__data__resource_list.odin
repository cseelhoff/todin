package game

import "core:fmt"

// games.strategy.engine.data.ResourceList

Resource_List :: struct {
	using game_data_component: Game_Data_Component,
	resources: map[string]^Resource,
}

// Java: public ResourceList(final GameData data)
resource_list_new :: proc(data: ^Game_Data) -> ^Resource_List {
	self := new(Resource_List)
	self.game_data_component = make_Game_Data_Component(data)
	self.resources = make(map[string]^Resource)
	return self
}

// Java: public void addResource(final Resource resource)
resource_list_add_resource :: proc(self: ^Resource_List, resource: ^Resource) {
	self.resources[default_named_get_name(&resource.named_attachable.default_named)] = resource
}

// Java: public Resource getResourceOrThrow(final @NonNls String name)
resource_list_get_resource_or_throw :: proc(self: ^Resource_List, name: string) -> ^Resource {
	resource := resource_list_get_resource_optional(self, name)
	if resource == nil {
		panic(fmt.tprintf("No resource named: %s", name))
	}
	return resource
}

// Java: public Optional<Resource> getResourceOptional(final String name)
resource_list_get_resource_optional :: proc(self: ^Resource_List, name: string) -> ^Resource {
	return self.resources[name]
}

// Java: public Collection<Resource> getResources()
// Returns `Collections.unmodifiableCollection(resources.values())`.
// In Odin we surface a fresh snapshot as a dynamic array of pointers;
// caller owns the returned array.
resource_list_get_resources :: proc(self: ^Resource_List) -> [dynamic]^Resource {
	out := make([dynamic]^Resource, 0, len(self.resources))
	for _, resource in self.resources {
		append(&out, resource)
	}
	return out
}

// Java synthetic lambda from `ResourceList.getResourceOrThrow(String name)`:
//   () -> new IllegalArgumentException("No resource named: " + name)
// Supplied to `Optional.orElseThrow` when the resource-name lookup
// returns null. Java's lambda is a zero-arg `Supplier` that captures
// the outer parameter `name`; in Odin we lift the captured string into
// a formal parameter (`name`), matching the `lambda$0` index. The Odin
// port has no dedicated IllegalArgumentException type, so the lambda
// allocates a `Throwable` shim (`java.lang.Throwable`) carrying the
// concatenated message — matching the convention used by
// `game_map_lambda_get_territory_or_throw_0`. The returned
// `^Throwable` is heap-allocated and owned by the caller; the
// concatenated `message` string is also heap-allocated (via
// `fmt.aprintf`) and owned alongside the Throwable.
resource_list_lambda_get_resource_or_throw_0 :: proc(name: string) -> ^Throwable {
	t := new(Throwable)
	t.message = fmt.aprintf("No resource named: %s", name)
	return t
}

