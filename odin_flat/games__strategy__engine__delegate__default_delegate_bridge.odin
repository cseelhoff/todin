package game

Default_Delegate_Bridge :: struct {
	using i_delegate_bridge:    I_Delegate_Bridge,
	game_data:                  ^Game_Data,
	game:                       ^Server_Game,
	history_writer:             ^I_Delegate_History_Writer,
	random_stats:               ^Random_Stats,
	delegate_execution_manager: ^Delegate_Execution_Manager,
	client_network_bridge:      ^Client_Network_Bridge,
	random_source:              ^I_Random_Source,
}

// Vtable shims: cast ^I_Delegate_Bridge back to ^Default_Delegate_Bridge
// and forward to the typed body. Mirrors the game_data_v_* pattern.
default_delegate_bridge_v_add_change :: proc(self: ^I_Delegate_Bridge, change: ^Change) {
	default_delegate_bridge_add_change(cast(^Default_Delegate_Bridge)self, change)
}
default_delegate_bridge_v_enter_delegate_execution :: proc(self: ^I_Delegate_Bridge) {
	default_delegate_bridge_enter_delegate_execution(cast(^Default_Delegate_Bridge)self)
}
default_delegate_bridge_v_get_history_writer :: proc(self: ^I_Delegate_Bridge) -> ^I_Delegate_History_Writer {
	return transmute(^I_Delegate_History_Writer)default_delegate_bridge_get_history_writer(cast(^Default_Delegate_Bridge)self)
}
default_delegate_bridge_v_get_game_player :: proc(self: ^I_Delegate_Bridge) -> ^Game_Player {
	return default_delegate_bridge_get_game_player(cast(^Default_Delegate_Bridge)self)
}
default_delegate_bridge_v_get_data :: proc(self: ^I_Delegate_Bridge) -> ^Game_Data {
	return default_delegate_bridge_get_data(cast(^Default_Delegate_Bridge)self)
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
	// Wire vtable so cast(^I_Delegate_Bridge)bridge dispatches through
	// proc-fields. Mirrors Java's `implements IDelegateBridge`.
	self.i_delegate_bridge.add_change               = default_delegate_bridge_v_add_change
	self.i_delegate_bridge.enter_delegate_execution = default_delegate_bridge_v_enter_delegate_execution
	self.i_delegate_bridge.get_history_writer       = default_delegate_bridge_v_get_history_writer
	self.i_delegate_bridge.get_game_player          = default_delegate_bridge_v_get_game_player
	self.i_delegate_bridge.get_data                 = default_delegate_bridge_v_get_data
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

// TEST-ONLY instrumentation hook (dep_mark_attacking_transports golden test).
// When dbg_add_change_capture_enabled is true, every top-level Change passed
// to default_delegate_bridge_add_change is captured into
// dbg_add_change_capture_changes BEFORE the composite-singleton unwrap and
// the server_game_add_change forwarding, and the proc short-circuits so the
// test does not need a fully-wired Server_Game. Production code never sets
// the flag; the hook is invisible to the snapshot harness.
dbg_add_change_capture_enabled: bool
dbg_add_change_capture_changes: [dynamic]^Change

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
	if dbg_add_change_capture_enabled {
		append(&dbg_add_change_capture_changes, change)
		return
	}
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
//
// In the headless snapshot harness no real IDisplay is registered with the
// messengers; the channel-broadcaster cast yields a Unified_Invocation_Handler
// reinterpreted as ^I_Display and dispatch through its proc-fields segfaults.
// Return a process-wide no-op display singleton so MustFightBattle.fight() can
// invoke battle_end / show_battle / list_battle_steps without crashing.
@(private="file") _no_op_display: ^I_Display
@(private="file") _no_op_display_battle_end :: proc(self: ^I_Display, battle_id: Uuid, message: string) {}
@(private="file") _no_op_display_bombing_results :: proc(self: ^I_Display, battle_id: Uuid, dice: [dynamic]^Die, cost: int) {}
@(private="file") _no_op_display_casualty_notification :: proc(self: ^I_Display, battle_id: Uuid, step: string, dice: ^Dice_Roll, player: ^Game_Player, killed: [dynamic]^Unit, damaged: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {}
@(private="file") _no_op_display_changed_units_notification :: proc(self: ^I_Display, battle_id: Uuid, player: ^Game_Player, removed_units: [dynamic]^Unit, added_units: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {}
@(private="file") _no_op_display_dead_unit_notification :: proc(self: ^I_Display, battle_id: Uuid, player: ^Game_Player, dead: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {}
@(private="file") _no_op_display_goto_battle_step :: proc(self: ^I_Display, battle_id: Uuid, step: string) {}
@(private="file") _no_op_display_list_battle_steps :: proc(self: ^I_Display, battle_id: Uuid, steps: [dynamic]string) {}
@(private="file") _no_op_display_notify_dice :: proc(self: ^I_Display, dice_roll: ^Dice_Roll, step_name: string) {}
@(private="file") _no_op_display_notify_retreat :: proc(self: ^I_Display, short_message: string, message: string, step: string, retreating_player: ^Game_Player) {}
@(private="file") _no_op_display_notify_retreat_units :: proc(self: ^I_Display, battle_id: Uuid, retreating: [dynamic]^Unit) {}
@(private="file") _no_op_display_report_message_to_all :: proc(self: ^I_Display, message: string, title: string, do_not_include_host: bool, do_not_include_clients: bool, do_not_include_observers: bool) {}
@(private="file") _no_op_display_report_message_to_players :: proc(self: ^I_Display, players_to_send_to: [dynamic]^Game_Player, players_to_exclude: [dynamic]^Game_Player, message: string, title: string) {}

default_delegate_bridge_get_display_channel_broadcaster :: proc(self: ^Default_Delegate_Bridge) -> ^I_Display {
	if _no_op_display == nil {
		d := new(I_Display)
		d.battle_end = _no_op_display_battle_end
		d.bombing_results = _no_op_display_bombing_results
		d.casualty_notification = _no_op_display_casualty_notification
		d.changed_units_notification = _no_op_display_changed_units_notification
		d.dead_unit_notification = _no_op_display_dead_unit_notification
		d.goto_battle_step = _no_op_display_goto_battle_step
		d.list_battle_steps = _no_op_display_list_battle_steps
		d.notify_dice = _no_op_display_notify_dice
		d.notify_retreat = _no_op_display_notify_retreat
		d.notify_retreat_units = _no_op_display_notify_retreat_units
		d.report_message_to_all = _no_op_display_report_message_to_all
		d.report_message_to_players = _no_op_display_report_message_to_players
		_no_op_display = d
	}
	return _no_op_display
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
	// In the headless snapshot harness no real Player is wired into the
	// messengers; the cast `(Player) getOutbound(implementor)` yields a
	// Unified_Invocation_Handler reinterpreted as ^Player and dispatch
	// through its proc-fields jumps to garbage. Return a process-wide
	// no-op Player singleton — its proc-fields are nil so all dispatch
	// helpers (player_select_casualties, player_report_error, etc.)
	// take their nil-fallback branch.
	@(static) singleton: ^Player
	if singleton == nil {
		singleton = new(Player)
	}
	return singleton
}

// Specialized lookup for retreat-query dispatch. Java routes
// `bridge.getRemotePlayer(retreatingPlayer)` through messengers to the
// AbstractProAi.retreatQuery override; the singleton above no-ops every
// dispatch which silently disables AI retreats (observed at WW2v5 r=1
// i=14 russianBattle West Russia: Java retreats fighter, Odin doesn't).
//
// We can't widen `get_remote_player` to look up the AI Player stub on
// `self.game.game_players` for ALL callers because many call sites
// (casualty selection, etc.) rely on the no-op singleton's nil fields
// to take default branches; switching them all to the AI stub crashes
// (russianPurchase segfault during odds-calc sims). Instead expose a
// narrow helper that the retreat path uses explicitly.
// Test-harness-registered remote-Player lookup keyed by Game_Player.
// In production, the bridge resolves remote players via messengers; in
// the snapshot harness there is no messenger, so test_server_game
// registers per-Game_Player AI Player stubs into this map and the
// retreat-query helper consults it. We use a global rather than
// reaching into `self.game.game_players` because some bridges seen at
// runtime (e.g. the temporary bridge built inside odds-calc sims for
// AI purchase) point at a different Server_Game whose game_players is
// uninitialized — accessing it segfaults.
default_delegate_bridge_remote_player_registry: map[^Game_Player]^Player

default_delegate_bridge_register_remote_player :: proc(
	game_player: ^Game_Player,
	player: ^Player,
) {
	if game_player == nil { return }
	default_delegate_bridge_remote_player_registry[game_player] = player
}

default_delegate_bridge_clear_remote_player_registry :: proc() {
	clear(&default_delegate_bridge_remote_player_registry)
}

default_delegate_bridge_get_remote_player_for_retreat :: proc(
	self: ^Default_Delegate_Bridge,
	game_player: ^Game_Player,
) -> ^Player {
	if game_player != nil {
		if p, ok := default_delegate_bridge_remote_player_registry[game_player]; ok && p != nil {
			return p
		}
	}
	return default_delegate_bridge_get_remote_player(self, game_player)
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
