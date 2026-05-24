package game

// Helpers that wrap map iteration in a sort order matching the Java
// `ProDeterminism` util on the oracle side. Both runtimes iterate
// in the same content-addressable order (territory name, unit UUID,
// player name, unit-type name), eliminating non-determinism caused
// by Java `LinkedHashMap` JVM-hash bucket order vs. Odin pointer-key
// hash order.
//
// See `deterministic-maps.md` for the running site tracker. Apply
// these at every map-iteration site whose order influences AI
// decisions; they have no effect on iteration sites whose order
// doesn't matter (logging, summing, etc).

import "core:slice"
import "core:strings"

// Returns territories in `m` sorted by territory name.
// Caller must `defer delete(<result>)`.
pro_determinism_sorted_territory_keys :: proc(
	m: $T/map[^Territory]$V,
) -> [dynamic]^Territory {
	out: [dynamic]^Territory
	for t in m {
		append(&out, t)
	}
	slice.sort_by(out[:], proc(a, b: ^Territory) -> bool {
		return strings.compare(territory_get_name(a), territory_get_name(b)) < 0
	})
	return out
}

// Returns units in `m` sorted by (unit-type name, already-moved).
// Stable sort is used so units that tie on every property keep
// the input collection's iteration order. UUID is deliberately
// NOT used (it may not survive game-state copies in all paths).
// When property-tied units affect AI decisions, fix the upstream
// iteration site so insertion order is deterministic instead of
// relying on a per-unit tiebreak.
@(private = "file")
pro_determinism_unit_property_less :: proc(a, b: ^Unit) -> bool {
	an := unit_type_get_name(unit_get_type(a))
	bn := unit_type_get_name(unit_get_type(b))
	if c := strings.compare(an, bn); c != 0 {
		return c < 0
	}
	return unit_get_already_moved(a) < unit_get_already_moved(b)
}

pro_determinism_sorted_unit_keys :: proc(
	m: $T/map[^Unit]$V,
) -> [dynamic]^Unit {
	out: [dynamic]^Unit
	for u in m {
		append(&out, u)
	}
	slice.stable_sort_by(out[:], pro_determinism_unit_property_less)
	return out
}

// Returns territories from a `[dynamic]^Territory` (or slice) sorted
// by name. Caller must `defer delete(<result>)`.
pro_determinism_sort_territories :: proc(
	ts: []^Territory,
) -> [dynamic]^Territory {
	out: [dynamic]^Territory
	for t in ts {
		append(&out, t)
	}
	slice.sort_by(out[:], proc(a, b: ^Territory) -> bool {
		return strings.compare(territory_get_name(a), territory_get_name(b)) < 0
	})
	return out
}

// Returns units from a slice sorted by (unit-type name, already-moved),
// with stable-sort tie-break to input order. Caller must
// `defer delete(<result>)`.
pro_determinism_sort_units :: proc(us: []^Unit) -> [dynamic]^Unit {
	out: [dynamic]^Unit
	for u in us {
		append(&out, u)
	}
	slice.stable_sort_by(out[:], pro_determinism_unit_property_less)
	return out
}

// Returns players in `m` sorted by player name.
// Caller must `defer delete(<result>)`.
pro_determinism_sorted_player_keys :: proc(
	m: $T/map[^Game_Player]$V,
) -> [dynamic]^Game_Player {
	out: [dynamic]^Game_Player
	for p in m {
		append(&out, p)
	}
	slice.sort_by(out[:], proc(a, b: ^Game_Player) -> bool {
		return strings.compare(game_player_get_name(a), game_player_get_name(b)) < 0
	})
	return out
}

// Returns unit types in `m` sorted by unit-type name.
// Caller must `defer delete(<result>)`.
pro_determinism_sorted_unit_type_keys :: proc(
	m: $T/map[^Unit_Type]$V,
) -> [dynamic]^Unit_Type {
	out: [dynamic]^Unit_Type
	for u in m {
		append(&out, u)
	}
	slice.sort_by(out[:], proc(a, b: ^Unit_Type) -> bool {
		return strings.compare(unit_type_get_name(a), unit_type_get_name(b)) < 0
	})
	return out
}
