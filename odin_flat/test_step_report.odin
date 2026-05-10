package game

// Per-step action reports for diagnosing AI behavior.
//
// Enabled with -define:STEP_REPORT=true. When on, captures a snapshot
// of game state BEFORE each step runs, then after the step compares
// against the snapshot and emits one or more "STEP" lines describing
// what the step actually did. Format is human-readable, intentionally
// distinct from DIGEST so both can co-exist.
//
// Reports per phase suffix:
//   *Purchase / *Bid          → unit types purchased (delta in player's hand)
//   *Combat / *Battle         → battles fought: location, attacker losses,
//                               defender losses, owner change
//   *NonCombatMove / *Move    → unit moves: type, owner, from→to
//   *Place                    → units placed: territory, owner, type:count
// Other steps emit nothing.

import "core:fmt"
import "core:slice"
import "core:strings"

STEP_REPORT :: #config(STEP_REPORT, false)

// One per-unit observation: where the unit currently lives (territory
// pointer or nil if in player's hand) and the player's PUs.
@(private = "file")
Unit_Loc :: struct {
	terr:       ^Territory,        // nil if in player hand
	owner:      ^Game_Player,
	type_name:  string,
}

Step_Snapshot :: struct {
	unit_loc:   map[^Unit]Unit_Loc, // every unit known at snapshot time
	pus:        map[string]i32,     // PUs per player name
}

// Take a snapshot of the entire game state. Cheap enough to do per-step
// for the full-game test (single-threaded).
test_step_report_snapshot :: proc(gd: ^Game_Data) -> Step_Snapshot {
	snap := Step_Snapshot{
		unit_loc = make(map[^Unit]Unit_Loc),
		pus      = make(map[string]i32),
	}
	if gd == nil { return snap }

	// Player hands + PUs.
	pl := game_data_get_player_list(gd)
	if pl != nil {
		for name, gp in pl.players {
			if gp == nil { continue }
			if gp.resources != nil {
				snap.pus[name] = resource_collection_get_quantity_by_name(gp.resources, "PUs")
			}
			uc := game_player_get_unit_collection(gp)
			if uc != nil {
				units := unit_collection_get_units(uc)
				defer delete(units)
				for u in units {
					if u == nil { continue }
					snap.unit_loc[u] = Unit_Loc{
						terr = nil, owner = u.owner,
						type_name = u.type != nil ? default_named_get_name(&u.type.named_attachable.default_named) : "?",
					}
				}
			}
		}
	}

	// Units on the map.
	gm := game_data_get_map(gd)
	if gm != nil {
		for t in gm.territories {
			if t == nil { continue }
			units := territory_get_units(t)
			defer delete(units)
			for u in units {
				if u == nil { continue }
				snap.unit_loc[u] = Unit_Loc{
					terr = t, owner = u.owner,
					type_name = u.type != nil ? default_named_get_name(&u.type.named_attachable.default_named) : "?",
				}
			}
		}
	}
	return snap
}

test_step_report_destroy :: proc(snap: ^Step_Snapshot) {
	delete(snap.unit_loc)
	delete(snap.pus)
}

@(private = "file")
fmt_terr :: proc(t: ^Territory) -> string {
	if t == nil { return "<hand>" }
	return default_named_get_name(&t.named_attachable.default_named)
}

@(private = "file")
fmt_player :: proc(p: ^Game_Player) -> string {
	if p == nil { return "-" }
	return default_named_get_name(&p.named_attachable.default_named)
}

// Sorted [territory_name → map[type_name → count]] aggregator.
@(private = "file")
TerrTypeAgg :: struct {
	terr:  string,
	owner: string,
	types: map[string]int,
}

@(private = "file")
group_sorted_terr :: proc(per_terr: map[string]^TerrTypeAgg) -> [dynamic]string {
	keys := make([dynamic]string)
	for k, _ in per_terr { append(&keys, k) }
	slice.sort(keys[:])
	return keys
}

@(private = "file")
fmt_types_sorted :: proc(types: map[string]int) -> string {
	keys := make([dynamic]string)
	defer delete(keys)
	for k, _ in types { append(&keys, k) }
	slice.sort(keys[:])
	b := strings.builder_make()
	first := true
	for k in keys {
		if !first { strings.write_string(&b, ",") }
		first = false
		fmt.sbprintf(&b, "%s:%d", k, types[k])
	}
	return strings.to_string(b)
}

// Emit step report. Compares `before` (pre-step snapshot) to live state
// after the step, and prints one or more STEP lines based on step type.
test_step_report_emit :: proc(gd: ^Game_Data, before: ^Step_Snapshot, round: i32, idx: i32, step_name: string, player_name: string) {
	if gd == nil || before == nil { return }
	after := test_step_report_snapshot(gd)
	defer test_step_report_destroy(&after)

	// Classify by suffix.
	is_purchase := strings.has_suffix(step_name, "Purchase") || strings.has_suffix(step_name, "Bid")
	is_battle   := strings.has_suffix(step_name, "Battle") || strings.has_suffix(step_name, "Combat")
	is_ncm      := strings.has_suffix(step_name, "NonCombatMove")
	is_combat_move := strings.has_suffix(step_name, "CombatMove")
	is_place    := strings.has_suffix(step_name, "Place")

	if !(is_purchase || is_battle || is_ncm || is_combat_move || is_place) {
		return
	}

	prefix := fmt.tprintf("STEP r=%d i=%d %s player=%s", round, idx, step_name, player_name)

	if is_purchase {
		// Units that appeared in `player_name`'s hand (terr == nil) post-step.
		bought_types := make(map[string]int)
		defer delete(bought_types)
		for u, loc in after.unit_loc {
			if loc.terr != nil { continue }
			owner_name := fmt_player(loc.owner)
			if owner_name != player_name { continue }
			if _, was := before.unit_loc[u]; was { continue } // not new
			bought_types[loc.type_name] = bought_types[loc.type_name] + 1
		}
		pu_before := before.pus[player_name]
		pu_after  := after.pus[player_name]
		fmt.printf("%s spent=%d bought=[%s]\n", prefix, pu_before - pu_after, fmt_types_sorted(bought_types))
		return
	}

	if is_combat_move || is_ncm {
		// Per-unit movements. Group by (from→to, owner, type) for
		// compactness: "5x Russian_inf Belorussia→Ukraine".
		Move_Key :: struct { from, to, owner, ut: string }
		moves := make(map[Move_Key]int)
		defer delete(moves)
		for u, after_loc in after.unit_loc {
			before_loc, was := before.unit_loc[u]
			if !was { continue } // unit didn't exist before — purchase/place artifact
			if before_loc.terr == after_loc.terr { continue }
			k := Move_Key{
				from  = fmt_terr(before_loc.terr),
				to    = fmt_terr(after_loc.terr),
				owner = fmt_player(after_loc.owner),
				ut    = after_loc.type_name,
			}
			moves[k] = moves[k] + 1
		}
		// Sort by (from, to, owner, ut) for byte-stable output.
		Sort_Entry :: struct { k: Move_Key, n: int }
		entries := make([dynamic]Sort_Entry)
		defer delete(entries)
		for k, n in moves { append(&entries, Sort_Entry{k, n}) }
		slice.sort_by(entries[:], proc(a, b: Sort_Entry) -> bool {
			if a.k.from != b.k.from { return a.k.from < b.k.from }
			if a.k.to   != b.k.to   { return a.k.to   < b.k.to }
			if a.k.owner != b.k.owner { return a.k.owner < b.k.owner }
			return a.k.ut < b.k.ut
		})
		if len(entries) == 0 {
			fmt.printf("%s moves=0\n", prefix)
		} else {
			for e in entries {
				fmt.printf("%s move %s %s %dx %s→%s\n",
					prefix, e.k.owner, e.k.ut, e.n, e.k.from, e.k.to)
			}
		}
		return
	}

	if is_battle {
		// A battle "happened" wherever units of an owner present before are gone
		// after, OR territory ownership changed. Group casualties by
		// (territory, owner_lost) → count.
		// Find territories with any change.
		// Build per-territory unit counts before/after by (owner, type).
		Loc_Key :: struct { terr: string, owner: string, ut: string }
		before_count := make(map[Loc_Key]int)
		defer delete(before_count)
		after_count  := make(map[Loc_Key]int)
		defer delete(after_count)
		for _, loc in before.unit_loc {
			if loc.terr == nil { continue }
			before_count[Loc_Key{fmt_terr(loc.terr), fmt_player(loc.owner), loc.type_name}] += 1
		}
		for _, loc in after.unit_loc {
			if loc.terr == nil { continue }
			after_count[Loc_Key{fmt_terr(loc.terr), fmt_player(loc.owner), loc.type_name}] += 1
		}
		// Per-territory losses: for each terr, sum (max(0, before-after)) per owner.
		Terr_Owner :: struct { terr, owner: string }
		losses := make(map[Terr_Owner]int)
		defer delete(losses)
		all_keys := make(map[Loc_Key]struct{})
		defer delete(all_keys)
		for k, _ in before_count { all_keys[k] = {} }
		for k, _ in after_count  { all_keys[k] = {} }
		for k, _ in all_keys {
			b := before_count[k]
			a := after_count[k]
			if b > a {
				losses[Terr_Owner{k.terr, k.owner}] += (b - a)
			}
		}
		if len(losses) == 0 {
			fmt.printf("%s battles=0\n", prefix)
			return
		}
		// Group losses by territory.
		terr_set := make(map[string]struct{})
		defer delete(terr_set)
		for to_, _ in losses { terr_set[to_.terr] = {} }
		terrs := make([dynamic]string)
		defer delete(terrs)
		for t, _ in terr_set { append(&terrs, t) }
		slice.sort(terrs[:])
		for terr_name in terrs {
			// Resolve current owner.
			cur_owner := "-"
			if gm := game_data_get_map(gd); gm != nil {
				if t := game_map_get_territory_or_null(gm, terr_name); t != nil {
					if op := territory_get_owner(t); op != nil {
						cur_owner = fmt_player(op)
					}
				}
			}
			// Per-side loss summary.
			loss_owners := make([dynamic]string)
			defer delete(loss_owners)
			for to_, _ in losses {
				if to_.terr == terr_name {
					append(&loss_owners, to_.owner)
				}
			}
			slice.sort(loss_owners[:])
			lb := strings.builder_make()
			first := true
			for o in loss_owners {
				if !first { strings.write_string(&lb, ",") }
				first = false
				fmt.sbprintf(&lb, "%s:%d", o, losses[Terr_Owner{terr_name, o}])
			}
			fmt.printf("%s battle at=%s new_owner=%s units_lost=[%s]\n",
				prefix, terr_name, cur_owner, strings.to_string(lb))
		}
		return
	}

	if is_place {
		// Units that appeared in territories owned by `player_name`,
		// grouped by (territory, type).
		per_terr := make(map[string]^TerrTypeAgg)
		defer {
			for _, agg in per_terr { delete(agg.types); free(agg) }
			delete(per_terr)
		}
		for u, after_loc in after.unit_loc {
			if after_loc.terr == nil { continue }
			before_loc, was := before.unit_loc[u]
			if was && before_loc.terr == after_loc.terr { continue }
			// Filter to placements by THIS player.
			if fmt_player(after_loc.owner) != player_name { continue }
			// Skip movement (was already on map elsewhere).
			if was && before_loc.terr != nil { continue }
			tn := fmt_terr(after_loc.terr)
			agg, ok := per_terr[tn]
			if !ok {
				agg = new(TerrTypeAgg)
				agg.terr  = tn
				agg.owner = fmt_player(after_loc.owner)
				agg.types = make(map[string]int)
				per_terr[tn] = agg
			}
			agg.types[after_loc.type_name] += 1
		}
		if len(per_terr) == 0 {
			fmt.printf("%s placed=0\n", prefix)
			return
		}
		keys := group_sorted_terr(per_terr)
		defer delete(keys)
		for tn in keys {
			agg := per_terr[tn]
			fmt.printf("%s placed at=%s owner=%s units=[%s]\n",
				prefix, agg.terr, agg.owner, fmt_types_sorted(agg.types))
		}
		return
	}
}
