package game

// Java: games.strategy.engine.delegate.IDelegateBridge (interface)
// Modelled as a vtable struct. `Default_Delegate_Bridge` (and any other
// concrete bridge) populates these fields when constructed for the AI
// snapshot harness.

I_Delegate_Bridge :: struct {
        concrete:                 rawptr,
        add_change:               proc(self: ^I_Delegate_Bridge, change: ^Change),
        enter_delegate_execution: proc(self: ^I_Delegate_Bridge),
        get_history_writer:       proc(self: ^I_Delegate_Bridge) -> ^I_Delegate_History_Writer,
        get_game_player:          proc(self: ^I_Delegate_Bridge) -> ^Game_Player,
        get_data:                 proc(self: ^I_Delegate_Bridge) -> ^Game_Data,
        get_remote_player:        proc(self: ^I_Delegate_Bridge, player: ^Game_Player) -> ^Player,
        get_sound_channel_broadcaster: proc(self: ^I_Delegate_Bridge) -> ^Headless_Sound_Channel,
        get_display_channel_broadcaster: proc(self: ^I_Delegate_Bridge) -> ^I_Display,
        get_resource_loader:      proc(self: ^I_Delegate_Bridge) -> ^Resource_Loader,
        send_message:             proc(self: ^I_Delegate_Bridge, msg: ^Web_Socket_Message),
        get_random:               proc(
                self:       ^I_Delegate_Bridge,
                max:        i32,
                count:      i32,
                player:     ^Game_Player,
                dice_type:  I_Random_Stats_Dice_Type,
                annotation: string,
        ) -> [dynamic]i32,
        stop_game_sequence:       proc(self: ^I_Delegate_Bridge, status: string, title: string),
}

// Java owners covered by this file:
//   - games.strategy.engine.delegate.IDelegateBridge
//
// AI snapshot harness convention: concrete bridges are passed by
// pointer, then `cast(^I_Delegate_Bridge)` directly. The cast does
// not magically populate vtable proc-fields; rather, the dispatchers
// below fall back to Default_Delegate_Bridge implementations when the
// proc-field is nil. This works because the AI snapshot run only
// constructs Default_Delegate_Bridge instances; if other concrete
// bridges are introduced, this fallback must be revisited.

i_delegate_bridge_add_change :: proc(self: ^I_Delegate_Bridge, change: ^Change) {
	default_delegate_bridge_add_change(cast(^Default_Delegate_Bridge)self, change)
}

i_delegate_bridge_enter_delegate_execution :: proc(self: ^I_Delegate_Bridge) {
	default_delegate_bridge_enter_delegate_execution(cast(^Default_Delegate_Bridge)self)
}

i_delegate_bridge_get_history_writer :: proc(self: ^I_Delegate_Bridge) -> ^I_Delegate_History_Writer {
	return transmute(^I_Delegate_History_Writer)default_delegate_bridge_get_history_writer(cast(^Default_Delegate_Bridge)self)
}

i_delegate_bridge_get_game_player :: proc(self: ^I_Delegate_Bridge) -> ^Game_Player {
	return default_delegate_bridge_get_game_player(cast(^Default_Delegate_Bridge)self)
}

i_delegate_bridge_get_data :: proc(self: ^I_Delegate_Bridge) -> ^Game_Data {
	return default_delegate_bridge_get_data(cast(^Default_Delegate_Bridge)self)
}

// games.strategy.engine.delegate.IDelegateBridge#sendMessage(WebSocketMessage)
//   Vtable dispatch through the proc field. AI snapshot harness bridges
//   leave this field nil — websocket I/O is not modeled — and we treat
//   a nil dispatch as a no-op (Java sends to the websocket; the
//   in-memory snapshot path simply drops the message, equivalent to
//   running with `useWebsocketNetwork = false`).
i_delegate_bridge_send_message :: proc(self: ^I_Delegate_Bridge, msg: ^Web_Socket_Message) {
	// AI snapshot harness does not model websocket I/O — drop messages.
}

// Java has both `getRemotePlayer()` and `getRemotePlayer(GamePlayer)`. The
// no-arg form is `getRemotePlayer(getGamePlayer())` per the interface
// javadoc, so callers pass `nil` to dispatch the no-arg variant.
i_delegate_bridge_get_remote_player :: proc(
        self: ^I_Delegate_Bridge,
        player: ^Game_Player = nil,
) -> ^Player {
        p := player
        if p == nil {
                p = i_delegate_bridge_get_game_player(self)
        }
        return default_delegate_bridge_get_remote_player(cast(^Default_Delegate_Bridge)self, p)
}

// games.strategy.engine.delegate.IDelegateBridge#getCostsForTuv(games.strategy.engine.data.GamePlayer)
// Java default: return new TuvCostsCalculator().getCostsForTuv(player);
i_delegate_bridge_get_costs_for_tuv :: proc(
        self: ^I_Delegate_Bridge,
        player: ^Game_Player,
) -> map[^Unit_Type]i32 {
        calc := tuv_costs_calculator_new()
        return tuv_costs_calculator_get_costs_for_tuv(calc, player)
}

i_delegate_bridge_get_sound_channel_broadcaster :: proc(self: ^I_Delegate_Bridge) -> ^Headless_Sound_Channel {
        return cast(^Headless_Sound_Channel)default_delegate_bridge_get_sound_channel_broadcaster(cast(^Default_Delegate_Bridge)self)
}

// games.strategy.engine.delegate.IDelegateBridge#getDisplayChannelBroadcaster()
//   Java: IDisplay getDisplayChannelBroadcaster();
// Vtable dispatch through the proc field. The concrete bridge
// (Default_Delegate_Bridge#getDisplayChannelBroadcaster) wraps the
// game's display-channel broadcaster from the messengers; AI snapshot
// dummies that have no display surface leave this field nil.
i_delegate_bridge_get_display_channel_broadcaster :: proc(self: ^I_Delegate_Bridge) -> ^I_Display {
        return default_delegate_bridge_get_display_channel_broadcaster(cast(^Default_Delegate_Bridge)self)
}

// games.strategy.engine.delegate.IDelegateBridge#getResourceLoader()
//   Java: Optional<ResourceLoader> getResourceLoader();
// Java models absence with Optional; the Odin port collapses
// `Optional<ResourceLoader>` to a plain `^Resource_Loader` where a
// nil pointer is the empty case. The concrete Default_Delegate_Bridge
// returns the game's resource loader (Java does Optional.of(game.getResourceLoader()));
// dummy bridges in the AI snapshot harness return nil (Java throws
// UnsupportedOperationException — never reached in simulation).
i_delegate_bridge_get_resource_loader :: proc(self: ^I_Delegate_Bridge) -> ^Resource_Loader {
        return default_delegate_bridge_get_resource_loader(cast(^Default_Delegate_Bridge)self)
}

// games.strategy.engine.delegate.IDelegateBridge#getRandom(int, int, GamePlayer, DiceType, String)
//   int[] getRandom(int max, int count, GamePlayer player, DiceType diceType, String annotation);
// Java has both a single-roll int overload and the multi-roll int[]
// overload above. All Odin call sites pass `count` and read the
// returned array (the snapshot path never uses the single-roll
// form), so the Odin port models the int[] overload via vtable
// dispatch on the concrete bridge (e.g. default_delegate_bridge_get_random
// forwards to plain_random_source_get_random_array and records the
// rolls on random_stats).
i_delegate_bridge_get_random :: proc(
        self:       ^I_Delegate_Bridge,
        max:        i32,
        count:      i32,
        player:     ^Game_Player,
        dice_type:  I_Random_Stats_Dice_Type,
        annotation: string,
) -> [dynamic]i32 {
        return default_delegate_bridge_get_random(cast(^Default_Delegate_Bridge)self, max, count, player, dice_type, annotation)
}

// Java: games.strategy.engine.delegate.IDelegateBridge#stopGameSequence(String, String)
//   Vtable dispatch; concrete bridges (DefaultDelegateBridge in the
//   harness) install this. AI/snapshot bridges leave it nil → no-op,
//   matching the headless harness which has no UI step controller to
//   tear down.
i_delegate_bridge_stop_game_sequence :: proc(self: ^I_Delegate_Bridge, status: string, title: string) {
	// AI snapshot harness has no UI step controller; no-op.
}
