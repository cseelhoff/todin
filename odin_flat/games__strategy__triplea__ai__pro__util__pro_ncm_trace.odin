package game

import "core:fmt"
import "core:slice"
import "core:strings"

// Debug-only checkpoint hashes for narrowing divergence inside pro_non_combat_move_ai.
// Off by default; enable with -define:NCM_TRACE=true.

NCM_TRACE :: #config(NCM_TRACE, false)

// Iter-42 per-unit identity probe. Independent of NCM_TRACE so it can be
// enabled at builds with RPO_DUMP only. Dumps the named territory's
// unit_collection.units as a sorted (type_name, owner_name) list to
// stderr so ASLR-induced unit-identity drift is visible.
pro_ncm_units_dump :: proc(label: string, player_name_filter: string, t_name: string, t: ^Territory) {
	when !#config(RPO_DUMP, false) { return }
	if t == nil || t.unit_collection == nil { return }
	type_owner: [dynamic][2]string
	defer delete(type_owner)
	for u in t.unit_collection.units {
		if u == nil { continue }
		tn := "?"
		if u.type != nil { tn = unit_type_get_name(u.type) }
		on := "?"
		if u.owner != nil { on = default_named_get_name(&u.owner.named_attachable.default_named) }
		append(&type_owner, [2]string{tn, on})
	}
	slice.sort_by(type_owner[:], proc(a, b: [2]string) -> bool {
		if a[0] != b[0] { return a[0] < b[0] }
		return a[1] < b[1]
	})
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	for to in type_owner {
		fmt.sbprintf(&sb, "%s|%s,", to[0], to[1])
	}
	fmt.eprintf("NCM_UNITS label=%s player=%s t=%s n=%d types=%s\n",
		label, player_name_filter, t_name, len(type_owner), strings.to_string(sb))
}

NCM_TRACE_DUMP :: #config(NCM_TRACE_DUMP, false)
NCM_HANG_PROBE :: #config(NCM_HANG_PROBE, false)

pro_ncm_hang_stage :: proc(player_name: string, stage: string) {
	when NCM_HANG_PROBE {
		if player_name == "Japanese" {
			fmt.eprintf("NCM_HANG.stage %s\n", stage)
		}
	}
}

@(private="file")
ncm_fnv1a64 :: proc(s: string) -> u64 {
	h: u64 = 0xcbf29ce484222325
	for i in 0..<len(s) {
		h ~= u64(s[i])
		h *= 0x100000001b3
	}
	return h
}

pro_ncm_trace_emit :: proc(label: string, move_map: ^map[^Territory]^Pro_Territory) {
	when !NCM_TRACE { return }
	if move_map == nil {
		fmt.printf("NCM_TRACE label=%s h=0000000000000000 n=0\n", label)
		return
	}
	names := make([dynamic]string)
	defer delete(names)
	lookup := make(map[string]^Pro_Territory)
	defer delete(lookup)
	for t, pt in move_map^ {
		if t == nil || pt == nil { continue }
		n := default_named_get_name(&t.named_attachable.default_named)
		append(&names, n)
		lookup[n] = pt
	}
	slice.sort(names[:])
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	for n in names {
		pt := lookup[n]
		units := pro_territory_get_units(pt)
		cant := pro_territory_get_cant_move_units(pt)
		mx := pro_territory_get_max_enemy_units(pt)
		v := pro_territory_get_value(pt)
		h := pro_territory_is_can_hold(pt) ? 1 : 0
		fmt.sbprintf(&sb, "%s|U=%d|C=%d|M=%d|V=%d|H=%d|",
			n, len(units), len(cant), len(mx), i64(v * 1000.0), h)
		when NCM_TRACE_DUMP {
			fmt.printf("NCM_DUMP label=%s t=%s U=%d C=%d M=%d V=%d H=%d\n",
				label, n, len(units), len(cant), len(mx), i64(v * 1000.0), h)
		}
	}
	fmt.printf("NCM_TRACE label=%s h=%016x n=%d\n",
		label, ncm_fnv1a64(strings.to_string(sb)), len(names))
	when NCM_TRACE_DUMP {
		for n in names {
			fmt.printf("NCM_DUMP label=%s t=%s\n", label, n)
		}
	}
}

pro_ncm_trace_emit_raw :: proc(label: string, move_map: ^map[^Territory]^Pro_Territory) {
	when !NCM_TRACE { return }
	if move_map == nil {
		fmt.printf("NCM_TRACE label=%s h=0000000000000000 n=0\n", label)
		return
	}
	names := make([dynamic]string)
	defer delete(names)
	for t, _ in move_map^ {
		if t == nil { continue }
		append(&names, default_named_get_name(&t.named_attachable.default_named))
	}
	slice.sort(names[:])
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	for n in names { fmt.sbprintf(&sb, "%s|", n) }
	fmt.printf("NCM_TRACE label=%s h=%016x n=%d\n",
		label, ncm_fnv1a64(strings.to_string(sb)), len(names))
	when NCM_TRACE_DUMP {
		for n in names {
			fmt.printf("NCM_DUMP label=%s t=%s\n", label, n)
		}
	}
}

pro_ncm_trace_emit_list :: proc(label: string, list: ^[dynamic]^Pro_Territory) {
	when !NCM_TRACE { return }
	if list == nil {
		fmt.printf("NCM_TRACE label=%s h=0000000000000000 n=0\n", label)
		return
	}
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	for pt, i in list^ {
		if pt == nil { continue }
		t := pt.territory
		n := default_named_get_name(&t.named_attachable.default_named)
		v := pro_territory_get_value(pt)
		units := pro_territory_get_units(pt)
		fmt.sbprintf(&sb, "%d=%s|V=%d|U=%d|", i, n, i64(v * 1000.0), len(units))
	}
	fmt.printf("NCM_TRACE label=%s h=%016x n=%d\n",
		label, ncm_fnv1a64(strings.to_string(sb)), len(list^))
	when NCM_TRACE_DUMP {
		for pt, i in list^ {
			if pt == nil { continue }
			t := pt.territory
			n := default_named_get_name(&t.named_attachable.default_named)
			v := pro_territory_get_value(pt)
			units := pro_territory_get_units(pt)
			fmt.printf("NCM_DUMP label=%s i=%d t=%s V=%d U=%d\n",
				label, i, n, i64(v * 1000.0), len(units))
		}
	}
}

// Iter-46 probe. Dumps per-player digest at NCM-exit / purchase-entry
// over the REAL game data (not the planner's copy). For each territory
// owned by `player_name_filter`, emits the sorted (type:count,...)
// summary so PASS vs FAIL runs can be diffed. ON only with
// -define:NCM_END_STATE=true.
NCM_END_STATE :: #config(NCM_END_STATE, false)

pro_ncm_end_state_dump :: proc(label: string, player_name_filter: string, data: ^Game_Data) {
	when !NCM_END_STATE { return }
	if data == nil { return }
	gm := game_data_get_map(data)
	if gm == nil { return }
	terrs := game_map_get_territories(gm)

	rows: [dynamic][2]string
	defer {
		for r in rows { delete(r[1]) }
		delete(rows)
	}

	for t in terrs {
		if t == nil { continue }
		owner := territory_get_owner(t)
		if owner == nil { continue }
		on := default_named_get_name(&owner.named_attachable.default_named)
		if on != player_name_filter { continue }
		if t.unit_collection == nil { continue }

		type_counts := make(map[string]int)
		defer delete(type_counts)
		for u in t.unit_collection.units {
			if u == nil || u.owner == nil { continue }
			uon := default_named_get_name(&u.owner.named_attachable.default_named)
			if uon != player_name_filter { continue }
			tn := "?"
			if u.type != nil { tn = unit_type_get_name(u.type) }
			type_counts[tn] += 1
		}

		type_keys := make([dynamic]string)
		defer delete(type_keys)
		for tn in type_counts { append(&type_keys, tn) }
		slice.sort(type_keys[:])

		sb := strings.builder_make()
		defer strings.builder_destroy(&sb)
		for tn in type_keys {
			fmt.sbprintf(&sb, "%s:%d,", tn, type_counts[tn])
		}

		tname := default_named_get_name(&t.named_attachable.default_named)
		summary := strings.clone(strings.to_string(sb))
		append(&rows, [2]string{tname, summary})
	}

	slice.sort_by(rows[:], proc(a, b: [2]string) -> bool { return a[0] < b[0] })

	for r in rows {
		fmt.eprintf("NCM_END_STATE label=%s player=%s t=%s units=%s\n",
			label, player_name_filter, r[0], r[1])
	}
}

// Iter-47 probe. Dumps the digest of a [dynamic]^Move_Description as a
// sorted list of (start_terr, end_terr, sorted(unit_type:count,...))
// triples, FNV-1a64 hashed. Lets us localise which step inside
// pro_non_combat_move_ai_do_move (calculate_move_routes /
// calculate_amphib_routes / inner-do_move merge / perform_move) is the
// nondeterministic one. Filter to one player by skipping move
// descriptions whose units are not all owned by `player_name_filter`.
MOVE_ROUTES_DIGEST :: #config(MOVE_ROUTES_DIGEST, false)

pro_move_routes_digest :: proc(
	label: string,
	player_name_filter: string,
	moves: ^[dynamic]^Move_Description,
) {
	when !MOVE_ROUTES_DIGEST { return }
	if moves == nil {
		fmt.eprintf("MOVE_ROUTES_DIGEST label=%s player=%s n=0 h=0000000000000000\n",
			label, player_name_filter)
		return
	}

	rows := make([dynamic]string)
	defer {
		for r in rows { delete(r) }
		delete(rows)
	}

	for m in moves^ {
		if m == nil { continue }
		// Filter: keep only moves where AT LEAST ONE unit is owned by
		// the filter player (matches iter-42 MOVE_PLAN behaviour).
		has_player_unit := false
		for u in m.units {
			if u == nil || u.owner == nil { continue }
			on := default_named_get_name(&u.owner.named_attachable.default_named)
			if on == player_name_filter { has_player_unit = true; break }
		}
		if !has_player_unit { continue }

		r := move_description_get_route(m)
		start := route_get_start(r)
		end := route_get_end(r)
		start_name := start != nil ? default_named_get_name(&start.named_attachable.default_named) : "?"
		end_name := end != nil ? default_named_get_name(&end.named_attachable.default_named) : "?"

		type_counts := make(map[string]int)
		defer delete(type_counts)
		for u in m.units {
			if u == nil { continue }
			tn := "?"
			if u.type != nil { tn = unit_type_get_name(u.type) }
			type_counts[tn] += 1
		}
		type_keys := make([dynamic]string)
		defer delete(type_keys)
		for tn in type_counts { append(&type_keys, tn) }
		slice.sort(type_keys[:])

		sb := strings.builder_make()
		defer strings.builder_destroy(&sb)
		fmt.sbprintf(&sb, "%s->%s|", start_name, end_name)
		for tn in type_keys {
			fmt.sbprintf(&sb, "%s:%d,", tn, type_counts[tn])
		}
		append(&rows, strings.clone(strings.to_string(sb)))
	}

	slice.sort(rows[:])

	combined := strings.builder_make()
	defer strings.builder_destroy(&combined)
	for r in rows {
		fmt.sbprintf(&combined, "%s|", r)
	}
	digest := ncm_fnv1a64(strings.to_string(combined))

	fmt.eprintf("MOVE_ROUTES_DIGEST label=%s player=%s n=%d h=%016x\n",
		label, player_name_filter, len(rows), digest)
	for r in rows {
		fmt.eprintf("  MOVE_ROUTES_DIGEST_ROW label=%s r=%s\n", label, r)
	}
}
