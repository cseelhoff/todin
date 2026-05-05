package game

Default_Delegate_Bridge :: struct {
	game_data:                  ^Game_Data,
	game:                       ^Server_Game,
	history_writer:             ^I_Delegate_History_Writer,
	random_stats:               ^Random_Stats,
	delegate_execution_manager: ^Delegate_Execution_Manager,
	client_network_bridge:      ^Client_Network_Bridge,
	random_source:              ^I_Random_Source,
}

make_Default_Delegate_Bridge :: proc(
	game_data: ^Game_Data,
	game: ^Server_Game,
	history_writer: ^I_Delegate_History_Writer,
	random_stats: ^Random_Stats,
	delegate_execution_manager: ^Delegate_Execution_Manager,
	client_network_bridge: ^Client_Network_Bridge,
	random_source: ^I_Random_Source,
) -> ^Default_Delegate_Bridge {
	self := new(Default_Delegate_Bridge)
	self.game_data = game_data
	self.game = game
	self.history_writer = history_writer
	self.random_stats = random_stats
	self.delegate_execution_manager = delegate_execution_manager
	self.client_network_bridge = client_network_bridge
	self.random_source = random_source
	return self
}

default_delegate_bridge_get_data :: proc(self: ^Default_Delegate_Bridge) -> ^Game_Data {
	return self.game_data
}

default_delegate_bridge_get_history_writer :: proc(self: ^Default_Delegate_Bridge) -> ^History_Writer {
	return transmute(^History_Writer)self.history_writer
}

default_delegate_bridge_leave_delegate_execution :: proc(self: ^Default_Delegate_Bridge) {
	delegate_execution_manager_leave_delegate_execution(self.delegate_execution_manager)
}

default_delegate_bridge_enter_delegate_execution :: proc(self: ^Default_Delegate_Bridge) {
	delegate_execution_manager_enter_delegate_execution(self.delegate_execution_manager)
}

default_delegate_bridge_get_game_player :: proc(self: ^Default_Delegate_Bridge) -> ^Game_Player {
	return game_step_get_player_id(game_sequence_get_step(game_data_get_sequence(self.game_data)))
}

default_delegate_bridge_get_random :: proc(
	self: ^Default_Delegate_Bridge,
	max: i32,
	count: i32,
	player: ^Game_Player,
	dice_type: I_Random_Stats_Dice_Type,
	annotation: string,
) -> [dynamic]i32 {
	random_values := plain_random_source_get_random_array(
		transmute(^Plain_Random_Source)self.random_source,
		max,
		count,
		annotation,
	)
	random_stats_add_random(self.random_stats, random_values[:], player, dice_type)
	return random_values
}

// Java: `private Object getOutbound(final Object o)`
//   final Class<?>[] interfaces = o.getClass().getInterfaces();
//   return delegateExecutionManager.newOutboundImplementation(o, interfaces);
//
// In the AI snapshot harness there is no reflection and no
// java.lang.reflect.Proxy: newOutboundImplementation collapses to a
// gameOver-gated pass-through that returns the implementor unchanged
// (see delegate_execution_manager_new_outbound_implementation). We
// therefore drop the o.getClass().getInterfaces() call (typeid list
// is unused by the helper) and forward an empty interface slice.
default_delegate_bridge_get_outbound :: proc(
	self: ^Default_Delegate_Bridge,
	o:    rawptr,
) -> rawptr {
	return delegate_execution_manager_new_outbound_implementation(
		self.delegate_execution_manager,
		o,
		nil,
	)
}

// games.strategy.engine.delegate.DefaultDelegateBridge#addChange(games.strategy.engine.data.Change)
// Java:
//   if (change instanceof CompositeChange) {
//     final CompositeChange c = (CompositeChange) change;
//     if (c.getChanges().size() == 1) { addChange(c.getChanges().get(0)); return; }
//   }
//   if (!change.isEmpty()) { game.addChange(change); }
//
// The composite-with-one-child shortcut unwraps trivial wrappers so that
// the broadcaster sees the inner change directly.
default_delegate_bridge_add_change :: proc(self: ^Default_Delegate_Bridge, change: ^Change) {
	if change != nil && change.kind == .Composite_Change {
		c := cast(^Composite_Change)change
		children := composite_change_get_changes(c)
		if len(children) == 1 {
			default_delegate_bridge_add_change(self, children[0])
			return
		}
	}
	if !change_is_empty(change) {
		server_game_add_change(self.game, change)
	}
}

// games.strategy.engine.delegate.DefaultDelegateBridge#getDisplayChannelBroadcaster()
// Java: implementor = game.getMessengers().getChannelBroadcaster(AbstractGame.getDisplayChannel());
//       return (IDisplay) getOutbound(implementor);
default_delegate_bridge_get_display_channel_broadcaster :: proc(self: ^Default_Delegate_Bridge) -> ^I_Display {
	implementor := messengers_get_channel_broadcaster(
		self.game.messengers,
		abstract_game_get_display_channel(),
	)
	return cast(^I_Display)default_delegate_bridge_get_outbound(self, rawptr(implementor))
}

// games.strategy.engine.delegate.DefaultDelegateBridge#getRemotePlayer(games.strategy.engine.data.GamePlayer)
// Java:
//   try {
//     Object implementor = game.getMessengers().getRemote(ServerGame.getRemoteName(gamePlayer));
//     return (Player) getOutbound(implementor);
//   } catch (RuntimeException e) {
//     if (e.getCause() instanceof MessengerException) throw new GameOverException("Game Over!");
//     throw e;
//   }
//
// Odin port has no exceptions and the messengers lookup does not raise
// (see player_bridge_get_remote_that_checks_for_game_over for the same
// rationale): the catch-MessengerException-wrap collapses to a direct
// pass-through.
default_delegate_bridge_get_remote_player :: proc(self: ^Default_Delegate_Bridge, game_player: ^Game_Player) -> ^Player {
	implementor := messengers_get_remote(
		self.game.messengers,
		server_game_get_remote_name_for_player(game_player),
	)
	return cast(^Player)default_delegate_bridge_get_outbound(self, rawptr(implementor))
}

// games.strategy.engine.delegate.DefaultDelegateBridge#getSoundChannelBroadcaster()
// Java: implementor = game.getMessengers().getChannelBroadcaster(AbstractGame.getSoundChannel());
//       return (ISound) getOutbound(implementor);
default_delegate_bridge_get_sound_channel_broadcaster :: proc(self: ^Default_Delegate_Bridge) -> ^I_Sound {
	implementor := messengers_get_channel_broadcaster(
		self.game.messengers,
		abstract_game_get_sound_channel(),
	)
	return cast(^I_Sound)default_delegate_bridge_get_outbound(self, rawptr(implementor))
}

// games.strategy.engine.delegate.DefaultDelegateBridge#getRemotePlayer()
// Java: return getRemotePlayer(getGamePlayer());
default_delegate_bridge_get_remote_player_current :: proc(self: ^Default_Delegate_Bridge) -> ^Player {
	return default_delegate_bridge_get_remote_player(
		self,
		default_delegate_bridge_get_game_player(self),
	)
}

// games.strategy.engine.delegate.DefaultDelegateBridge#getResourceLoader()
// Java: return Optional.of(game.getResourceLoader());
//
// AbstractGame#getResourceLoader() throws if the loader has not been
// set; Optional.of() likewise rejects null. The Odin port collapses
// Optional<ResourceLoader> to a plain `^Resource_Loader` where nil
// means absent — Server_Game embeds Abstract_Game (`using abstract_game`)
// so the loader lives at `self.game.resource_loader`.
default_delegate_bridge_get_resource_loader :: proc(self: ^Default_Delegate_Bridge) -> ^Resource_Loader {
	return self.game.resource_loader
}
