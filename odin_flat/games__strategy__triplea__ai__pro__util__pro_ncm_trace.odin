package game

import "core:fmt"
import "core:slice"
import "core:strings"

// Debug-only checkpoint hashes for narrowing divergence inside pro_non_combat_move_ai.
// Off by default; enable with -define:NCM_TRACE=true.

NCM_TRACE :: #config(NCM_TRACE, false)
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
