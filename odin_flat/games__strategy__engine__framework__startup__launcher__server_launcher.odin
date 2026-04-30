package game

SERVER_LAUNCHER_RELAY_SERVER_PORT :: 6000

Server_Launcher :: struct {
	using i_launcher: I_Launcher,
	game_data:                                 ^Game_Data,
	game_selector_model:                       ^Game_Selector_Model,
	launch_action:                             ^Launch_Action,
	client_count:                              i32,
	messengers:                                ^Messengers,
	player_listing:                            ^Player_Listing,
	remote_players:                            map[string]^I_Node,
	server_model:                              ^Server_Model,
	server_game:                               ^Server_Game,
	server_ready:                              ^Server_Launcher_Server_Ready,
	error_latch:                               ^Count_Down_Latch,
	is_launching:                              bool,
	abort_launch:                              bool,
	game_stopped:                              bool,
	observers_that_tried_to_join_during_startup: [dynamic]^I_Node,
	in_game_lobby_watcher:                     ^In_Game_Lobby_Watcher_Wrapper,
	game_relay_server:                         ^Game_Relay_Server,
}

// Java: lambda inside `launchInternal` passed to `Interruptibles.await`.
//   () -> {
//     if (!abortLaunch
//         && !errorLatch.await(
//             ClientSetting.serverObserverJoinWaitTime.getValueOrThrow(),
//             TimeUnit.SECONDS)) {
//       log.warn("Waiting on error latch timed out!");
//     }
//   }
// `serverObserverJoinWaitTime` defaults to 180 in
// ClientSetting.java; inlined here because the IntegerClientSetting
// global is not part of the AI snapshot harness surface.
server_launcher_lambda_launch_internal_0 :: proc(self: ^Server_Launcher) {
	if !self.abort_launch &&
		!count_down_latch_await_timeout(self.error_latch, 180, .SECONDS) {
		// Java: log.warn("Waiting on error latch timed out!")
	}
}

// Java: ServerReady.countDownAll — release every pending client slot.
//   for (int i = 0; i < clients; i++) latch.countDown();
server_launcher_server_ready_count_down_all :: proc(self: ^Server_Launcher_Server_Ready) {
	for i: i32 = 0; i < self.clients; i += 1 {
		count_down_latch_count_down(self.latch)
	}
}

// Java: lambda inside ServerReady.await passed to Interruptibles.await.
//   () -> latch.await(timeout, timeUnit)
server_launcher_server_ready_lambda_await_0 :: proc(
	self: ^Server_Launcher_Server_Ready,
	timeout: i64,
	unit: Time_Unit,
) -> bool {
	return count_down_latch_await_timeout(self.latch, timeout, unit)
}

