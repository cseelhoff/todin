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

// Sort key for units: every property that game-mechanically
// distinguishes one unit from another. Two units that tie on this
// full key are functionally interchangeable — the AI may pick
// either one and the resulting game state is the same. The snap
// digest groups by `unit_type:count`, so order inside a fungibility
// class never reaches the comparison.
//
// UUID is deliberately NOT used. Java's `UUID.randomUUID()` is
// non-deterministic across JVM runs, and even on the Odin side a
// UUID-based tie-break hides the real question (are these units
// genuinely fungible?) behind an opaque key. If two units tie on
// every property below, then by definition any planner choice
// between them produces equivalent observable state.
//
// Properties, in order: unit-type name, owner name, hits taken,
// movement used this turn (already_moved), was-amphibious flag
// (land units that came off transports), submerged flag (subs),
// is-currently-transported flag, unloaded-units count (transports
// that unloaded this turn), unloaded-to territory name.
//
// NOT included: current location (the territory the unit is
// standing on). A unit doesn't carry its own location — the
// AI's `pro_data.unit_territory_map` is the lookup. Use
// `pro_determinism_sorted_unit_keys_with_loc` (or `_sort_units_with_loc`)
// at iteration sites whose input set spans multiple territories;
// it adds location as a final tie-break.
pro_determinism_unit_property_less :: proc(a, b: ^Unit) -> bool {
	// type name
	an := unit_type_get_name(unit_get_type(a))
	bn := unit_type_get_name(unit_get_type(b))
	if c := strings.compare(an, bn); c != 0 { return c < 0 }
	// owner name
	ao := unit_get_owner(a); bo := unit_get_owner(b)
	aon := ""; bon := ""
	if ao != nil { aon = game_player_get_name(ao) }
	if bo != nil { bon = game_player_get_name(bo) }
	if c := strings.compare(aon, bon); c != 0 { return c < 0 }
	// hits taken
	if ah, bh := unit_get_hits(a), unit_get_hits(b); ah != bh { return ah < bh }
	// movement used this turn
	if aam, bam := unit_get_already_moved(a), unit_get_already_moved(b); aam != bam {
		return aam < bam
	}
	// was amphibious (land unit came off a transport this turn)
	if awa, bwa := unit_get_was_amphibious(a), unit_get_was_amphibious(b); awa != bwa {
		return !awa && bwa
	}
	// submerged (subs)
	if asu, bsu := unit_get_submerged(a), unit_get_submerged(b); asu != bsu {
		return !asu && bsu
	}
	// is currently being transported (presence only — not the
	// transporter's identity, to avoid recursive comparison)
	atb := unit_get_transported_by(a) != nil
	btb := unit_get_transported_by(b) != nil
	if atb != btb { return !atb && btb }
	// unloaded units this turn (transports that unloaded)
	au := unit_get_unloaded(a); bu := unit_get_unloaded(b)
	if len(au) != len(bu) { return len(au) < len(bu) }
	// unloaded-to territory (transports — destination name, "" if none)
	aut := unit_get_unloaded_to(a); but := unit_get_unloaded_to(b)
	autn := ""; butn := ""
	if aut != nil { autn = territory_get_name(aut) }
	if but != nil { butn = territory_get_name(but) }
	if c := strings.compare(autn, butn); c != 0 { return c < 0 }
	return false
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

// Returns units in `m` sorted by the fungibility key from
// `pro_determinism_unit_property_less`, with current location
// (territory name) as the final tie-break. Use this at iteration
// sites whose input set can span multiple territories — without
// the location tie-break, two interchangeable units (same type,
// owner, hits, moves, etc.) at different territories sort in
// stable-sort fallback order, which depends on the input map's
// pointer-key iteration order.
//
// `pro_data` must be non-nil; its `unit_territory_map` provides
// the location lookup. Units absent from the map are treated as
// having location "" (sorts first), matching the Java side's
// null-territory convention.
//
// Caller must `defer delete(<result>)`.
pro_determinism_sorted_unit_keys_with_loc :: proc(
	m: $T/map[^Unit]$V,
	pro_data: ^Pro_Data,
) -> [dynamic]^Unit {
	out: [dynamic]^Unit
	for u in m {
		append(&out, u)
	}
	pro_determinism_sort_with_loc_inplace_(out[:], pro_data)
	return out
}

// Sorts `us` in-place by the fungibility key + location tie-break.
// Shared helper for `_with_loc` overloads; uses the AI's
// `unit_territory_map` for location lookup.
@(private = "file")
pro_determinism_sort_with_loc_inplace_ :: proc(us: []^Unit, pro_data: ^Pro_Data) {
	utm: map[^Unit]^Territory
	if pro_data != nil {
		utm = pro_data_get_unit_territory_map(pro_data)
	}
	loc_name :: proc(utm: map[^Unit]^Territory, u: ^Unit) -> string {
		t, ok := utm[u]
		if !ok || t == nil { return "" }
		return territory_get_name(t)
	}
	// `slice.sort_by` takes a procedure value; we need to close over
	// `utm` without a runtime closure. Bind via a context-style trick:
	// pre-compute (key,unit) pairs and sort those.
	Tagged :: struct { u: ^Unit, terr_name: string }
	tagged := make([dynamic]Tagged, 0, len(us))
	defer delete(tagged)
	for u in us {
		append(&tagged, Tagged{u, loc_name(utm, u)})
	}
	slice.sort_by(tagged[:], proc(a, b: Tagged) -> bool {
		if pro_determinism_unit_property_less(a.u, b.u) { return true }
		if pro_determinism_unit_property_less(b.u, a.u) { return false }
		return strings.compare(a.terr_name, b.terr_name) < 0
	})
	for t, i in tagged { us[i] = t.u }
}

// Deprecated alias — `_with_uuid` was the prior UUID-tiebreak
// variant. UUIDs were removed because `UUID.randomUUID()` is
// non-deterministic across JVM runs. Call sites should migrate to
// `pro_determinism_sorted_unit_keys_with_loc` and pass the AI's
// `Pro_Data`. This shim falls back to the location-blind sort,
// which is wrong for multi-territory inputs.
pro_determinism_sorted_unit_keys_with_uuid :: proc(
	m: $T/map[^Unit]$V,
) -> [dynamic]^Unit {
	return pro_determinism_sorted_unit_keys(m)
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
