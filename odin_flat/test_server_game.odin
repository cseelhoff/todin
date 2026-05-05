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

// Adapter for the snapshot harness. Each snapshot test wraps a loaded
// Game_Data in a Test_Server_Game and invokes this proc; the proc
// composes a minimal Server_Game from the harness's field set and
// dispatches to the canonical `server_game_run_next_step` so the
// snapshot exercises the real Java-port code path.
//
// The fields the harness owns are mapped 1:1; everything else on
// Server_Game is left at its zero value. With
// `delegate_autosaves_enabled = false` (set by the harness), the
// auto-save short-circuits never reach `launch_action`, so the
// nil pointers there don't matter for snapshot runs.
test_server_game_run_next_step :: proc(self: ^Test_Server_Game) {
	sg := new(Server_Game)
	defer free(sg)
	sg.game_data = self.data
	sg.is_game_over = self.game_over
	sg.first_run = self.first_run
	sg.delegate_autosaves_enabled = self.delegate_autosaves_enabled
	sg.need_to_initialize = self.need_to_initialize
	sg.delegate_execution_stopped = self.stop_on_delegate
	sg.stop_game_on_delegate_execution_stop = false
	server_game_run_next_step(sg)
	// Reflect any state changes back so the harness's diff sees them.
	self.game_over = sg.is_game_over
	self.first_run = sg.first_run
	self.need_to_initialize = sg.need_to_initialize
}

