package game

Game_To_Lobby_Connection :: struct {
	lobby_client:         ^Http_Lobby_Client,
	lobby_watcher_client: ^Lobby_Watcher_Client,
	web_socket:           ^Web_Socket,
	public_visible_ip:    ^Inet_Address,
}

// Java: GameToLobbyConnection.disconnect(String gameId)
//   AsyncRunner.runAsync(() -> lobbyWatcherClient.removeGame(gameId))
//       .exceptionally(e -> log.info("Could not complete lobby game remove call", e));
// In Odin's single-threaded snapshot harness AsyncRunner.runAsync runs the
// task synchronously and there are no exceptions, so the runAsync/exceptionally
// wrapping is a no-op — invoke the underlying remove_game directly. Odin's
// bare `proc()` type cannot carry the captured `gameId`, so the lambda is
// inlined rather than passed through async_runner_run_async.
game_to_lobby_connection_disconnect :: proc(self: ^Game_To_Lobby_Connection, game_id: string) {
	if self == nil {
		return
	}
	lobby_watcher_client_remove_game(self.lobby_watcher_client, game_id)
}

