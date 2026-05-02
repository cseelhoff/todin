package game

import "core:fmt"

Player_Bridge :: struct {
	game:             ^IGame,
	step_name:        string,
	current_delegate: string,
}

player_bridge_get_step_name :: proc(self: ^Player_Bridge) -> string {
	return self.step_name
}

// Listener body for the GAME_STEP_CHANGED Java lambda in the
// PlayerBridge constructor:
//   this.stepName        = game.getData().getSequence().getStep().getName();
//   this.currentDelegate = game.getData().getSequence().getStep().getDelegate().getName();
player_bridge_on_game_step_changed :: proc(ctx: rawptr) {
	self := cast(^Player_Bridge)ctx
	data := i_game_get_data(self.game)
	step := game_sequence_get_step(game_data_get_sequence(data))
	self.step_name = game_step_get_name(step)
	self.current_delegate = i_delegate_get_name(game_step_get_delegate(step))
}

// games.strategy.engine.player.PlayerBridge#<init>(games.strategy.engine.framework.IGame)
//
// Java:
//   public PlayerBridge(final IGame game) {
//     this.game = game;
//     game.getData()
//         .addGameDataEventListener(
//             GameDataEvent.GAME_STEP_CHANGED,
//             () -> {
//               this.stepName = game.getData().getSequence().getStep().getName();
//               this.currentDelegate = game.getData().getSequence().getStep().getDelegate().getName();
//             });
//   }
player_bridge_new :: proc(game: ^I_Game) -> ^Player_Bridge {
	self := new(Player_Bridge)
	self.game = game
	game_data_add_game_data_event_listener(
		i_game_get_data(game),
		.Game_Step_Changed,
		player_bridge_on_game_step_changed,
		self,
	)
	return self
}

// games.strategy.engine.player.PlayerBridge#getGameData()
player_bridge_get_game_data :: proc(self: ^Player_Bridge) -> ^Game_Data {
	return i_game_get_data(self.game)
}

// games.strategy.engine.player.PlayerBridge#isGameOver()
player_bridge_is_game_over :: proc(self: ^Player_Bridge) -> bool {
	return i_game_is_game_over(self.game)
}

// games.strategy.engine.player.PlayerBridge#getRemoteThatChecksForGameOver(IRemote)
// Java wraps `implementor` in a JDK dynamic proxy whose only job is to convert
// RemoteNotFoundException / post-game-over invocation failures into
// GameOverException. The Odin port has no exceptions and no reflection, so the
// proxy is a semantic no-op — return the implementor directly.
player_bridge_get_remote_that_checks_for_game_over :: proc(self: ^Player_Bridge, implementor: ^I_Remote) -> ^I_Remote {
	return implementor
}

// games.strategy.engine.player.PlayerBridge#getRemoteDelegate()
// Java throws GameOverException → panic (Odin port has no exceptions).
// The try-with-resources on game.getData().acquireReadLock() is a no-op
// in the single-threaded snapshot harness. The Preconditions.checkState
// for an absent delegate becomes a panic with the same diagnostic. The
// surrounding catch-RuntimeException-with-MessengerException-cause block
// is unreachable here because messengers_get_remote does not raise.
player_bridge_get_remote_delegate :: proc(self: ^Player_Bridge) -> ^I_Remote {
	if i_game_is_game_over(self.game) {
		panic("Game Over")
	}
	data := i_game_get_data(self.game)
	game_data_acquire_read_lock(data)
	delegate := game_data_get_delegate_optional(data, self.current_delegate)
	if delegate == nil {
		panic(
			fmt.tprintf(
				"IDelegate in PlayerBridge.getRemote() cannot be null. CurrentStep: %s, and CurrentDelegate: %s",
				self.step_name,
				self.current_delegate,
			),
		)
	}
	remote_name := server_game_get_remote_name_for_delegate(delegate)
	return player_bridge_get_remote_that_checks_for_game_over(
		self,
		messengers_get_remote(i_game_get_messengers(self.game), remote_name),
	)
}
