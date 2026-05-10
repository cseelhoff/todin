package game

// Lightweight per-action narration for debugging AI behavior.
// Enabled with `-define:NARRATE=true`. Emits one line per action to
// stderr so it interleaves with normal logging but doesn't pollute
// snapshot/digest stdout.
//
// Hooked into:
//   - purchase_delegate_purchase            (purchase event)
//   - abstract_place_delegate_place_units   (placement event)
//   - transport_tracker_load_transport_change   (load event)
//   - transport_tracker_unload_transport_change (unload event)
//   - must_fight_battle_{attacker_wins,defender_wins,nobody_wins}
//     (battle resolution, includes TUV swing)

import "core:fmt"
import "core:os"

NARRATE :: #config(NARRATE, false)

narrate_purchase :: proc(player_name: string, transcript: string) {
	when NARRATE {
		fmt.fprintf(os.stderr, "[NARR] PURCHASE %s: %s\n", player_name, transcript)
	}
}

narrate_place :: proc(player_name: string, territory_name: string, units: [dynamic]^Unit) {
	when NARRATE {
		// Group by unit type for compactness.
		counts: map[string]int
		defer delete(counts)
		for u in units {
			t := unit_get_type(u)
			name := t != nil ? t.named.base.name : "<nil>"
			counts[name] = counts[name] + 1
		}
		fmt.fprintf(os.stderr, "[NARR] PLACE %s @ %s:", player_name, territory_name)
		for k, v in counts {
			fmt.fprintf(os.stderr, " %dx%s", v, k)
		}
		fmt.fprintf(os.stderr, "\n")
	}
}

narrate_load :: proc(transport: ^Unit, unit: ^Unit) {
	when NARRATE {
		owner := unit_get_owner(transport)
		owner_name := owner != nil ? owner.base.name : "<nil>"
		t_type := unit_get_type(transport)
		u_type := unit_get_type(unit)
		fmt.fprintf(
			os.stderr,
			"[NARR] LOAD %s: %s loaded onto %s\n",
			owner_name,
			u_type != nil ? u_type.named.base.name : "<nil>",
			t_type != nil ? t_type.named.base.name : "<nil>",
		)
	}
}

narrate_unload :: proc(unit: ^Unit, territory: ^Territory) {
	when NARRATE {
		owner := unit_get_owner(unit)
		owner_name := owner != nil ? owner.base.name : "<nil>"
		u_type := unit_get_type(unit)
		fmt.fprintf(
			os.stderr,
			"[NARR] UNLOAD %s: %s unloaded @ %s\n",
			owner_name,
			u_type != nil ? u_type.named.base.name : "<nil>",
			territory != nil ? territory.base.name : "<nil>",
		)
	}
}

narrate_battle :: proc(
	attacker_name:   string,
	defender_name:   string,
	site_name:       string,
	outcome:         string,
	attacker_lost_tuv: i32,
	defender_lost_tuv: i32,
) {
	// Removed: per-battle TUV reporting was unreliable (Odin's
	// must_fight_battle does not currently populate attacker_lost_tuv /
	// defender_lost_tuv). Combat phase territory-ownership delta is now
	// reported via narrate_ownership_delta (called from test_server_game
	// around combat/battle steps).
}

// Snapshot of who owns each territory. Cheap to take per-step.
Owner_Snapshot :: struct {
	owner_by_terr: map[^Territory]^Game_Player,
}

narrate_ownership_snapshot :: proc(gd: ^Game_Data) -> Owner_Snapshot {
	snap := Owner_Snapshot{ owner_by_terr = make(map[^Territory]^Game_Player) }
	if gd == nil { return snap }
	gm := game_data_get_map(gd)
	if gm == nil { return snap }
	for t in gm.territories {
		if t == nil { continue }
		snap.owner_by_terr[t] = territory_get_owner(t)
	}
	return snap
}

narrate_ownership_destroy :: proc(snap: ^Owner_Snapshot) {
	delete(snap.owner_by_terr)
}

// Diff `before` against current state, and emit one line per territory
// whose owner changed during the step.
narrate_ownership_delta :: proc(gd: ^Game_Data, before: ^Owner_Snapshot, step_name: string) {
	when NARRATE {
		if gd == nil || before == nil { return }
		gm := game_data_get_map(gd)
		if gm == nil { return }
		any_change := false
		for t in gm.territories {
			if t == nil { continue }
			old_owner, ok := before.owner_by_terr[t]
			if !ok { continue }
			new_owner := territory_get_owner(t)
			if old_owner == new_owner { continue }
			any_change = true
			old_name := old_owner != nil ? old_owner.base.name : "<nobody>"
			new_name := new_owner != nil ? new_owner.base.name : "<nobody>"
			fmt.fprintf(os.stderr,
				"[NARR] OWN_CHANGE %s: %s  %s -> %s\n",
				step_name, t.base.name, old_name, new_name)
		}
		if !any_change {
			fmt.fprintf(os.stderr, "[NARR] OWN_CHANGE %s: (no territory changed hands)\n", step_name)
		}
	}
}
