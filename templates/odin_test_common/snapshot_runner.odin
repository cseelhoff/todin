package test_common

import "core:testing"
import "core:log"
import game "../../odin_flat"

FILTER_SNAP :: #config(FILTER_SNAP, "")

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

	pass_count := 0
	fail_count := 0

	for id in ids {
		if FILTER_SNAP != "" && id != FILTER_SNAP { continue }
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

		run_proc(server_game)

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
