package game

import "core:fmt"
import "core:strings"

// games.strategy.engine.data.ResourceCollection
//
// Per-player wallet: Resource → quantity.

Integer_Map_Resource :: map[^Resource]i32

Resource_Collection :: struct {
	using game_data_component: Game_Data_Component,
	resources: Integer_Map_Resource,
}

// public static final int MAX_FIT_VALUE = 10000
RESOURCE_COLLECTION_MAX_FIT_VALUE :: 10000

// public ResourceCollection(final GameData data)
resource_collection_new :: proc(data: ^Game_Data) -> ^Resource_Collection {
	self := new(Resource_Collection)
	self.game_data_component = make_Game_Data_Component(data)
	self.resources = make(Integer_Map_Resource)
	return self
}

// private void change(final Resource resource, final int quantity)
// Mirrors IntegerMap.add(key, qty): resources[resource] += quantity.
resource_collection_change :: proc(self: ^Resource_Collection, resource: ^Resource, quantity: i32) {
	existing, _ := self.resources[resource]
	self.resources[resource] = existing + quantity
}

// public int getQuantity(final Resource resource)
// IntegerMap.getInt returns 0 for missing keys.
resource_collection_get_quantity :: proc(self: ^Resource_Collection, resource: ^Resource) -> i32 {
	value, ok := self.resources[resource]
	if !ok {
		return 0
	}
	return value
}

// public boolean isEmpty()
resource_collection_is_empty :: proc(self: ^Resource_Collection) -> bool {
	return len(self.resources) == 0
}

// games.strategy.engine.data.ResourceCollection#lambda$fitsHowOften$0(java.util.Map$Entry)
//
// Java synthetic method backing the mapToInt lambda inside fitsHowOften:
//   costEntry -> {
//     int resourceCost = costEntry.getValue();
//     if (resourceCost == 0) {
//       return MAX_FIT_VALUE;
//     } else {
//       return this.resources.getInt(costEntry.getKey()) / resourceCost;
//     }
//   }
// Captures `this`; takes a Map.Entry<Resource, Integer>. Odin lacks
// Map.Entry; the entry is passed as (key, value) which is how callers
// iterate cost.entrySet().
resource_collection_lambda_fits_how_often_0 :: proc(self: ^Resource_Collection, entry_key: ^Resource, entry_value: i32) -> i32 {
	resource_cost := entry_value
	if resource_cost == 0 {
		return RESOURCE_COLLECTION_MAX_FIT_VALUE
	}
	return resource_collection_get_quantity(self, entry_key) / resource_cost
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

// games.strategy.engine.data.ResourceCollection#lambda$fitsHowOften$1(org.triplea.java.collections.IntegerMap)
//
// Java synthetic method backing the orElseThrow supplier inside
// fitsHowOften:
//   () -> new IllegalArgumentException(
//             MessageFormat.format(
//                 "Could not calculate how often cost of {0} can be paid with resources {1}",
//                 cost, this.resources))
// Captures `cost` (the IntegerMap parameter) and `this`; the bytecode
// signature is therefore `(IntegerMap)` on a non-static method.
// Reproduces IntegerMap.toString() format: "IntegerMap:\n<name> -> <n>\n"
// (or "IntegerMap:\nempty\n" for an empty map). Resource.toString()
// resolves to the resource's name via Named.
resource_collection_lambda_fits_how_often_1 :: proc(self: ^Resource_Collection, cost: ^Integer_Map_Resource) -> ^Exception {
	cost_text := resource_collection_format_integer_map(cost)
	defer delete(cost_text)
	resources_text := resource_collection_format_integer_map(&self.resources)
	defer delete(resources_text)
	msg := fmt.aprintf(
		"Could not calculate how often cost of %s can be paid with resources %s",
		cost_text,
		resources_text,
	)
	return exception_new(msg)
}

// Mirrors org.triplea.java.collections.IntegerMap#toString() so the
// orElseThrow supplier above produces the same exception message Java
// would emit. Local to the lambda; not part of IntegerMap's own API.
resource_collection_format_integer_map :: proc(m: ^Integer_Map_Resource) -> string {
	b: strings.Builder
	strings.builder_init(&b)
	strings.write_string(&b, "IntegerMap:\n")
	if len(m^) == 0 {
		strings.write_string(&b, "empty\n")
	} else {
		for resource, value in m^ {
			strings.write_string(&b, resource.named.base.name)
			strings.write_string(&b, " -> ")
			strings.write_int(&b, int(value))
			strings.write_byte(&b, '\n')
		}
	}
	return strings.to_string(b)
}
