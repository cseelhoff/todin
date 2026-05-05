package game

// Harness-only wrapper used by the snapshot runner
// (`triplea/conversion/odin_tests/test_common/snapshot_runner.odin`).
// Mirrors the small subset of ServerGame state that the harness reads
// when wrapping a loaded ^Game_Data into a callable ServerGame instance
// for `server_game_run_next_step`. Field names match the harness's
// authoritative access pattern; do not rename without updating the
// harness via scripts/patch_triplea.py.
Test_Server_Game :: struct {
	data:                       ^Game_Data,
	game_over:                  bool,
	stop_on_delegate:           bool,
	delegate_autosaves_enabled: bool,
	need_to_initialize:         bool,
	first_run:                  bool,
}
