package game

import "core:fmt"

Casualty_Order_Of_Losses :: struct {}

@(private="file")
casualty_order_of_losses_ool_cache: map[string][dynamic]^Casualty_Order_Of_Losses_Amphib_Type

casualty_order_of_losses_clear_ool_cache :: proc() {
	clear(&casualty_order_of_losses_ool_cache)
}

// Java: CasualtyOrderOfLosses#computeOolCacheKey(Parameters, List<AmphibType>)
//
// Mirrors Java's
//   parameters.player.getName()
//     + "|" + parameters.battlesite.getName()
//     + "|" + parameters.combatValue.getBattleSide()
//     + "|" + Objects.hashCode(targetTypes)
//
// `Combat_Value` is the empty interface stub in odin_flat/, so there is
// no virtual dispatch for `getBattleSide()`. Each `^Combat_Value` instance
// represents exactly one battle side, so its pointer identity is a strict
// refinement of the side enum and yields the same cache-discrimination
// behavior the Java key relies on.
//
// `Objects.hashCode(List)` in Java is the List.hashCode contract:
//     int h = 1; for (T e : list) h = 31*h + Objects.hashCode(e);
// AmphibType is a Lombok @Value, so its hashCode combines its two fields
// (`type` identity hash, `isAmphibious` bool hash) the same way.
casualty_order_of_losses_compute_ool_cache_key :: proc(
	parameters: ^Casualty_Order_Of_Losses_Parameters,
	target_types: [dynamic]^Casualty_Order_Of_Losses_Amphib_Type,
) -> string {
	player_name := default_named_get_name(&parameters.player.named_attachable.default_named)
	battlesite_name := default_named_get_name(&parameters.battlesite.named_attachable.default_named)

	// List.hashCode contract.
	list_hash: i32 = 1
	for amphib in target_types {
		// AmphibType.hashCode (@Value): 31 * (31 + type-hash) + bool-hash,
		// which equals 31 * type-hash + bool-hash + 31 (Lombok's
		// PRIME=59 in newer versions, but the JDK default for List uses 31;
		// we follow List.hashCode here and treat AmphibType.hashCode as
		// `31 * Objects.hashCode(type) + Boolean.hashCode(isAmphibious)`,
		// i.e. an order-stable mix of its fields).
		type_hash: i32
		if amphib != nil {
			type_hash = i32(uintptr(rawptr(amphib.type)) & 0x7fffffff)
			bool_hash: i32 = 1237
			if amphib.is_amphibious {
				bool_hash = 1231
			}
			elem_hash := 31 * type_hash + bool_hash
			list_hash = 31 * list_hash + elem_hash
		} else {
			list_hash = 31 * list_hash
		}
	}

	return fmt.tprintf(
		"%s|%s|%p|%d",
		player_name,
		battlesite_name,
		rawptr(parameters.combat_value),
		list_hash,
	)
}
