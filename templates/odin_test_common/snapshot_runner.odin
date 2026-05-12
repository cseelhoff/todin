package test_common

import "core:testing"
import "core:log"
import "core:strings"
import "core:fmt"
import game "../../odin_flat"

FILTER_SNAP :: #config(FILTER_SNAP, "")
SNAP_DUMP   :: #config(SNAP_DUMP, false)

// Diagnostic dump (gated by -define:SNAP_DUMP=true) of every unit position
// in actual vs expected post-step game states. Format per line:
//   SNAP_DUMP <ACT|EXP> snap=<id> terr=<name> uid=<short> type=<t> owner=<p> aM=<f>
snap_dump_units :: proc(actual: ^game.Game_Data, expected: ^game.Game_Data, id: string) {
	when !SNAP_DUMP { return }
	emit("ACT", id, actual)
	emit("EXP", id, expected)
}

@(private = "file")
emit :: proc(label, id_: string, gd: ^game.Game_Data) {
	for terr in game.game_map_get_territories(game.game_data_get_map(gd)) {
		tname := game.territory_get_name(terr)
		for u in game.territory_get_units(terr) {
			ut := game.unit_get_type(u)
			ow := game.unit_get_owner(u)
			utn := ut == nil ? "?" : game.unit_type_get_name(ut)
			own := ow == nil ? "?" : game.game_player_get_name(ow)
			fmt.printf("SNAP_DUMP %s snap=%s terr=%s uid=%02x%02x%02x%02x type=%s owner=%s aM=%.1f\n",
				label, id_, tname, u.id[0], u.id[1], u.id[2], u.id[3], utn, own, game.unit_get_already_moved(u))
		}
	}
}

filter_snap_value :: proc() -> string {
	// Allow `-define:FILTER_SNAP="0013"` (shell-passed quotes preserved
	// by Odin) and strip a surrounding pair of double-quotes if present.
	s := FILTER_SNAP
	if len(s) >= 2 && s[0] == '"' && s[len(s)-1] == '"' {
		s = s[1:len(s)-1]
	}
	return strings.trim_space(s)
}

// Generic snapshot test runner.
// advance_step: if true, advances sequence.current_index after calling run_proc
//   (needed when the proc doesn't advance the step itself, e.g. delegate stubs)
run_snapshot_tests :: proc(
	t: ^testing.T,
	snapshot_dir: string,
	run_proc: proc(data: ^game.Game_Data),
	advance_step: bool = false,
) {
	ids := list_snapshot_ids(snapshot_dir)
	if len(ids) == 0 {
		log.warnf("No snapshots found in %s", snapshot_dir)
		return
	}
	log.infof("Running %d snapshot tests from %s", len(ids), snapshot_dir)

	pass_count := 0
	fail_count := 0

	for id in ids {
		before := load_game_state(snapshot_dir, id, "before.json")
		if before == nil {
			testing.expectf(t, false, "Failed to load before.json for snapshot %s", id)
			continue
		}
		after_expected := load_game_state(snapshot_dir, id, "after.json")
		if after_expected == nil {
			testing.expectf(t, false, "Failed to load after.json for snapshot %s", id)
			continue
		}

		// Run the proc under test — it mutates `before` in place
		run_proc(before)

		// Optionally advance step index (for procs that don't advance internally)
		if advance_step && before.sequence != nil {
			before.sequence.current_index += 1
			if int(before.sequence.current_index) >= len(before.sequence.steps) {
				before.sequence.current_index = 0
				before.sequence.round += 1
			}
		}

		// Compare mutated state to expected
		diff := compare_game_states(before, after_expected)
		if diff != "" {
			fail_count += 1
			testing.expectf(t, false, "Snapshot %s FAILED: %s", id, diff)
		} else {
			pass_count += 1
		}
	}

	log.infof("Results: %d passed, %d failed out of %d snapshots", pass_count, fail_count, len(ids))
}

// Variant that wraps Game_Data in a Test_Server_Game before calling the proc.
// Used for procs like server_game_run_next_step that take ^Test_Server_Game.
run_snapshot_tests_server_game :: proc(
	t: ^testing.T,
	snapshot_dir: string,
	run_proc: proc(g: ^game.Test_Server_Game),
) {
	ids := list_snapshot_ids(snapshot_dir)
	if len(ids) == 0 {
		log.warnf("No snapshots found in %s", snapshot_dir)
		return
	}
	log.infof("Running %d snapshot tests from %s", len(ids), snapshot_dir)
	filter := filter_snap_value()
	if filter != "" {
		log.infof("FILTER_SNAP active: only running %s", filter)
	}

	pass_count := 0
	fail_count := 0

	for id in ids {
		if filter != "" && id != filter { continue }
		log.infof("=== running snapshot %s ===", id)
		before := load_game_state(snapshot_dir, id, "before.json")
		if before == nil {
			testing.expectf(t, false, "Failed to load before.json for snapshot %s", id)
			continue
		}
		after_expected := load_game_state(snapshot_dir, id, "after.json")
		if after_expected == nil {
			testing.expectf(t, false, "Failed to load after.json for snapshot %s", id)
			continue
		}

		server_game := new(game.Test_Server_Game)
		server_game.data = before
		server_game.game_over = false
		server_game.stop_on_delegate = false
		server_game.delegate_autosaves_enabled = false
		// Each snapshot runs one step in isolation; by the time any non-init
		// step runs in Java, firstRun has already been flipped false by the
		// init-step bailout. needToInitialize stays true until the first real
		// game step commits the whoAmI change. The snapshot for step 1
		// (gameInitDelegate) still bails on step.player==nil, so first_run=false
		// is safe there too.
		server_game.need_to_initialize = true
		server_game.first_run = false

		// Pull captured RNG state from before-meta.txt so the harness
		// seeds PlainRandomSource MT and java_math_random LCG to match
		// Java's ACCUMULATED state at this step (Java's snapshot run
		// builds RNG state across all prior steps; reseeding fresh-42
		// per snap diverges by step ~13 onwards).
		rng := load_snapshot_rng_state(snapshot_dir, id, "before-meta.txt")
		if rng.mt_bytes != nil {
			server_game.mt_state = rng.mt_bytes
			server_game.mt_state_present = true
		}
		if rng.math_seed_present {
			server_game.math_random_seed = rng.math_seed
			server_game.math_random_present = true
		}

		run_proc(server_game)

		if filter != "" {
			snap_dump_units(server_game.data, after_expected, id)
		}

		diff := compare_game_states(before, after_expected)
		if diff != "" {
			fail_count += 1
			testing.expectf(t, false, "Snapshot %s FAILED: %s", id, diff)
		} else {
			pass_count += 1
		}
	}

	log.infof("Results: %d passed, %d failed out of %d snapshots", pass_count, fail_count, len(ids))
}
