package game

import "core:fmt"
import "core:strconv"

Unit_Damage_Received_Change :: struct {
	using change: Change,
	new_total_damage:      map[string]i32,
	old_total_damage:      map[string]i32,
	territories_to_notify: [dynamic]string,
}

// Java: UnitDamageReceivedChange#<init>(Map<String,Integer>, Map<String,Integer>,
//                                       Collection<String>)
// The Lombok-generated all-args private constructor used by `invert()`.
// Stores the three fields verbatim.
unit_damage_received_change_new_from_maps :: proc(
	new_total_damage: map[string]i32,
	old_total_damage: map[string]i32,
	territories_to_notify: [dynamic]string,
) -> ^Unit_Damage_Received_Change {
	udrc := new(Unit_Damage_Received_Change)
	udrc.kind = .Unit_Damage_Received_Change
	udrc.new_total_damage = new_total_damage
	udrc.old_total_damage = old_total_damage
	udrc.territories_to_notify = territories_to_notify
	return udrc
}

// Java: UnitDamageReceivedChange#<init>(IntegerMap<Unit>, Collection<Territory>)
//
// Mirrors the public constructor: build `newTotalDamage` keyed by each
// unit's UUID (as the canonical 8-4-4-4-12 hex string) with the supplied
// damage value; build `oldTotalDamage` from the same UUID keys with each
// unit's current `hits`; and capture the names of `territoriesToNotify`.
unit_damage_received_change_new_from_integer_map :: proc(
	total_damage: ^Integer_Map_Unit,
	territories_to_notify: [dynamic]^Territory,
) -> ^Unit_Damage_Received_Change {
	udrc := new(Unit_Damage_Received_Change)
	udrc.kind = .Unit_Damage_Received_Change
	udrc.new_total_damage = make(map[string]i32, len(total_damage.entries))
	udrc.old_total_damage = make(map[string]i32, len(total_damage.entries))
	for unit, damage in total_damage.entries {
		id := unit.id
		key := fmt.aprintf(
			"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
			id[0], id[1], id[2], id[3],
			id[4], id[5],
			id[6], id[7],
			id[8], id[9],
			id[10], id[11], id[12], id[13], id[14], id[15],
		)
		udrc.new_total_damage[key] = damage
		udrc.old_total_damage[key] = unit.hits
	}
	udrc.territories_to_notify = make([dynamic]string, 0, len(territories_to_notify))
	for territory in territories_to_notify {
		append(&udrc.territories_to_notify, territory.named.base.name)
	}
	return udrc
}

// Java: lambda inside `perform(GameState data)` —
//   newTotalDamage.forEach((unitId, damage) -> {
//     final Unit unit = data.getUnits().get(UUID.fromString(unitId));
//     if (unit != null) { unit.setHits(damage); }
//   });
// `data` is captured; in Odin the BiConsumer is rewritten as a free
// proc that takes the captured value as its first argument.
unit_damage_received_change_lambda_perform_0 :: proc(
	data: ^Game_State,
	unit_id: string,
	damage: i32,
) {
	parsed: Uuid
	ok := true
	read := 0
	for i := 0; i < len(unit_id) && read < 16; i += 1 {
		if unit_id[i] == '-' { continue }
		if i + 1 >= len(unit_id) { ok = false; break }
		v, parse_ok := strconv.parse_uint(unit_id[i:i+2], 16)
		if !parse_ok { ok = false; break }
		parsed[read] = u8(v)
		read += 1
		i += 1
	}
	if !ok || read != 16 {
		return
	}
	game_data := cast(^Game_Data)data
	unit := units_list_get(game_data_get_units(game_data), parsed)
	if unit != nil {
		unit_set_hits(unit, damage)
	}
}

// Java: UnitDamageReceivedChange#invert()
// Mirrors `new UnitDamageReceivedChange(oldTotalDamage, newTotalDamage,
// territoriesToNotify)` via the private all-args constructor: swap the
// new/old damage maps so applying the inverted change restores the
// previous totals, while preserving the same territories-to-notify list.
unit_damage_received_change_invert :: proc(self: ^Unit_Damage_Received_Change) -> ^Change {
	result := new(Unit_Damage_Received_Change)
	result.kind = .Unit_Damage_Received_Change
	result.new_total_damage = self.old_total_damage
	result.old_total_damage = self.new_total_damage
	result.territories_to_notify = self.territories_to_notify
	return &result.change
}

// Java: UnitDamageReceivedChange#perform(GameState data)
//   newTotalDamage.forEach((unitId, damage) -> {
//     final Unit unit = data.getUnits().get(UUID.fromString(unitId));
//     if (unit != null) { unit.setHits(damage); }
//   });
//   for (final String territory : territoriesToNotify) {
//     data.getMap().getTerritoryOrNull(territory).notifyChanged();
//   }
unit_damage_received_change_perform :: proc(self: ^Unit_Damage_Received_Change, data: ^Game_State) {
	for unit_id, damage in self.new_total_damage {
		unit_damage_received_change_lambda_perform_0(data, unit_id, damage)
	}
	for territory in self.territories_to_notify {
		territory_notify_changed(game_map_get_territory_or_null(game_state_get_map(data), territory))
	}
}
