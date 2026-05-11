package game

import "core:fmt"
import "core:slice"
import "core:strings"

// Debug-only checkpoint hashes for narrowing divergence inside pro_purchase_ai.
// Off by default; enable with -define:PUR_TRACE=true.

PUR_TRACE :: #config(PUR_TRACE, false)
PUR_TRACE_DUMP :: #config(PUR_TRACE_DUMP, false)

@(private = "file")
pur_fnv1a64 :: proc(s: string) -> u64 {
	h: u64 = 0xcbf29ce484222325
	for i in 0 ..< len(s) {
		h ~= u64(s[i])
		h *= 0x100000001b3
	}
	return h
}

// Hash of (per place_territory) name + n_units + sorted unit type names.
// Iteration is over purchase_territories.values()'s can_place_territories,
// keys collected by territory name and sorted to be deterministic.
pro_pur_trace_emit :: proc(
	label:                string,
	purchase_territories: ^map[^Territory]^Pro_Purchase_Territory,
	player_filter:        string = "",
) {
	when !PUR_TRACE {return}
	if purchase_territories == nil {
		fmt.printf("PUR_TRACE label=%s h=0000000000000000 n=0\n", label)
		return
	}
	rows := make([dynamic]string)
	defer {
		for r in rows {delete(r)}
		delete(rows)
	}
	for _, ppt in purchase_territories^ {
		if ppt == nil {continue}
		for place_territory in pro_purchase_territory_get_can_place_territories(ppt) {
			t := pro_place_territory_get_territory(place_territory)
			if t == nil {continue}
			tn := default_named_get_name(&t.named_attachable.default_named)
			units := pro_place_territory_get_place_units(place_territory)
			ut_names := make([dynamic]string)
			defer delete(ut_names)
			for u in units {
				ut := unit_get_type(u)
				utn := default_named_get_name(&ut.named_attachable.default_named)
				append(&ut_names, utn)
			}
			slice.sort(ut_names[:])
			sb := strings.builder_make()
			fmt.sbprintf(&sb, "%s|N=%d|", tn, len(units))
			for n in ut_names {fmt.sbprintf(&sb, "%s,", n)}
			append(&rows, strings.to_string(sb))
		}
	}
	slice.sort(rows[:])
	full := strings.builder_make()
	defer strings.builder_destroy(&full)
	for r in rows {fmt.sbprintf(&full, "%s|", r)}
	fmt.printf(
		"PUR_TRACE label=%s h=%016x n=%d\n",
		label,
		pur_fnv1a64(strings.to_string(full)),
		len(rows),
	)
	when PUR_TRACE_DUMP {
		for r in rows {
			fmt.printf("PUR_DUMP label=%s row=%s\n", label, r)
		}
	}
	_ = player_filter
}
