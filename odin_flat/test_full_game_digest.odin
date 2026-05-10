package game

// Per-step state digest for the full-game determinism probe.
//
// Emits one line per delegate step, BEFORE the step runs, so that
// diffing the Java vs Odin digest streams localizes the FIRST step
// at which the two ports diverge. Format is intentionally compact
// and stable so `diff -u java.tsv odin.tsv | head` is the bisection.
//
// Enabled with -define:DIGEST=true; default off for normal runs.
//
// Format (single line per step):
//   DIGEST r=R i=I step=NAME player=P PUs=[Russians:24,Germans:10,...]
//          terr=[Russians:24,Germans:14,...] units=N owner_h=HEX uc_h=HEX
//
// All maps are emitted sorted by key so the line is byte-stable.
// owner_h = FNV-1a64 over sorted "Territory=Owner|..." string.
// uc_h    = FNV-1a64 over sorted "Territory=UnitCount|..." string.

import "core:fmt"
import "core:slice"
import "core:strings"

DIGEST :: #config(DIGEST, false)
DIGEST_DETAIL_R :: #config(DIGEST_DETAIL_R, -1)
DIGEST_DETAIL_I :: #config(DIGEST_DETAIL_I, -1)

@(private="file")
fnv1a64 :: proc(s: string) -> u64 {
	h: u64 = 0xcbf29ce484222325
	for i in 0..<len(s) {
		h ~= u64(s[i])
		h *= 0x100000001b3
	}
	return h
}

// Emit one digest line. Safe to call with any ^Game_Data the loader/runner has;
// missing pieces just print as empty / 0.
test_full_game_digest_emit :: proc(gd: ^Game_Data) {
	if gd == nil {
		fmt.printf("DIGEST gd=nil\n")
		return
	}
	seq := game_data_get_sequence(gd)
	round: i32 = -1
	idx:   i32 = -1
	step_name := ""
	player_name := "-"
	if seq != nil {
		round = seq.round
		idx = seq.current_index
		if int(idx) >= 0 && int(idx) < len(seq.steps) {
			st := seq.steps[idx]
			if st != nil {
				step_name = st.name
				if st.player != nil {
					player_name = default_named_get_name(&st.player.named_attachable.default_named)
				}
			}
		}
	}

	// Build sorted player list once.
	pl := game_data_get_player_list(gd)
	player_names := make([dynamic]string)
	defer delete(player_names)
	if pl != nil {
		for name, _ in pl.players {
			append(&player_names, name)
		}
	}
	slice.sort(player_names[:])

	// PUs per player (skip null player; "PUs" resource).
	pus_buf := strings.builder_make()
	defer strings.builder_destroy(&pus_buf)
	first := true
	for name in player_names {
		gp := pl.players[name]
		if gp == nil || gp.resources == nil { continue }
		// Java's PlayerList.getPlayers() excludes the null player; mirror that.
		if game_player_is_null(gp) { continue }
		q := resource_collection_get_quantity_by_name(gp.resources, "PUs")
		if !first { strings.write_string(&pus_buf, ",") }
		first = false
		fmt.sbprintf(&pus_buf, "%s:%d", name, q)
	}

	// Territory owners + counts. Iterate territories in sorted order by name.
	gm := game_data_get_map(gd)
	terr_names := make([dynamic]string)
	defer delete(terr_names)
	terr_lookup := make(map[string]^Territory)
	defer delete(terr_lookup)
	if gm != nil {
		for t in gm.territories {
			if t == nil { continue }
			tn := default_named_get_name(&t.named_attachable.default_named)
			append(&terr_names, tn)
			terr_lookup[tn] = t
		}
	}
	slice.sort(terr_names[:])

	owner_pairs := strings.builder_make()
	defer strings.builder_destroy(&owner_pairs)
	uc_pairs := strings.builder_make()
	defer strings.builder_destroy(&uc_pairs)
	owner_count := make(map[string]int)
	defer delete(owner_count)
	total_units := 0
	for tn in terr_names {
		t := terr_lookup[tn]
		owner := "-"
		if op := territory_get_owner(t); op != nil {
			owner = default_named_get_name(&op.named_attachable.default_named)
		}
		units := territory_get_units(t)
		uc := len(units)
		delete(units)
		total_units += uc
		owner_count[owner] = owner_count[owner] + 1
		fmt.sbprintf(&owner_pairs, "%s=%s|", tn, owner)
		fmt.sbprintf(&uc_pairs, "%s=%d|", tn, uc)
	}
	owner_h := fnv1a64(strings.to_string(owner_pairs))
	uc_h    := fnv1a64(strings.to_string(uc_pairs))

	terr_buf := strings.builder_make()
	defer strings.builder_destroy(&terr_buf)
	owners_sorted := make([dynamic]string)
	defer delete(owners_sorted)
	for k, _ in owner_count {
		append(&owners_sorted, k)
	}
	slice.sort(owners_sorted[:])
	first = true
	for k in owners_sorted {
		if !first { strings.write_string(&terr_buf, ",") }
		first = false
		fmt.sbprintf(&terr_buf, "%s:%d", k, owner_count[k])
	}

	fmt.printf(
		"DIGEST r=%d i=%d step=%s player=%s PUs=[%s] terr=[%s] units=%d owner_h=%016x uc_h=%016x\n",
		round, idx, step_name, player_name,
		strings.to_string(pus_buf), strings.to_string(terr_buf),
		total_units, owner_h, uc_h,
	)

	// Detailed per-territory dump for one specific (round, step). Emit
	// "DETAIL r=R i=I terr=NAME owner=O units=N types=[Russian_inf:3,Russian_arm:1,...]".
	if int(round) == DIGEST_DETAIL_R && int(idx) == DIGEST_DETAIL_I {
		for tn in terr_names {
			t := terr_lookup[tn]
			owner := "-"
			if op := territory_get_owner(t); op != nil {
				owner = default_named_get_name(&op.named_attachable.default_named)
			}
			units := territory_get_units(t)
			defer delete(units)
			type_count := make(map[string]int)
			defer delete(type_count)
			for u in units {
				if u == nil { continue }
				ut_name := "?"
				oo := "-"
				if u.type != nil {
					ut_name = default_named_get_name(&u.type.named_attachable.default_named)
				}
				if u.owner != nil {
					oo = default_named_get_name(&u.owner.named_attachable.default_named)
				}
				key := fmt.aprintf("%s_%s", oo, ut_name)
				defer delete(key)
				type_count[strings.clone(key)] = type_count[key] + 1
			}
			keys := make([dynamic]string)
			defer delete(keys)
			for k, _ in type_count {
				append(&keys, k)
			}
			slice.sort(keys[:])
			tb := strings.builder_make()
			defer strings.builder_destroy(&tb)
			f := true
			for k in keys {
				if !f { strings.write_string(&tb, ",") }
				f = false
				fmt.sbprintf(&tb, "%s:%d", k, type_count[k])
			}
			fmt.printf("DETAIL r=%d i=%d terr=%s owner=%s units=%d types=[%s]\n",
				round, idx, tn, owner, len(units), strings.to_string(tb))
			for k in keys { delete(k) }
		}
	}
}
