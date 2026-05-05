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
}

// Java owners covered by this file:
//   - games.strategy.engine.delegate.IDelegateBridge

i_delegate_bridge_add_change :: proc(self: ^I_Delegate_Bridge, change: ^Change) {
        self.add_change(self, change)
}

i_delegate_bridge_enter_delegate_execution :: proc(self: ^I_Delegate_Bridge) {
        self.enter_delegate_execution(self)
}

i_delegate_bridge_get_history_writer :: proc(self: ^I_Delegate_Bridge) -> ^I_Delegate_History_Writer {
        return self.get_history_writer(self)
}

i_delegate_bridge_get_game_player :: proc(self: ^I_Delegate_Bridge) -> ^Game_Player {
        return self.get_game_player(self)
}

i_delegate_bridge_get_data :: proc(self: ^I_Delegate_Bridge) -> ^Game_Data {
        return self.get_data(self)
}

// games.strategy.engine.delegate.IDelegateBridge#sendMessage(WebSocketMessage)
//   Vtable dispatch through the proc field. AI snapshot harness bridges
//   leave this field nil — websocket I/O is not modeled — and we treat
//   a nil dispatch as a no-op (Java sends to the websocket; the
//   in-memory snapshot path simply drops the message, equivalent to
//   running with `useWebsocketNetwork = false`).
i_delegate_bridge_send_message :: proc(self: ^I_Delegate_Bridge, msg: ^Web_Socket_Message) {
        if self != nil && self.send_message != nil {
                self.send_message(self, msg)
        }
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
                p = self.get_game_player(self)
        }
        return self.get_remote_player(self, p)
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
        return self.get_sound_channel_broadcaster(self)
}

// games.strategy.engine.delegate.IDelegateBridge#getDisplayChannelBroadcaster()
//   Java: IDisplay getDisplayChannelBroadcaster();
// Vtable dispatch through the proc field. The concrete bridge
// (Default_Delegate_Bridge#getDisplayChannelBroadcaster) wraps the
// game's display-channel broadcaster from the messengers; AI snapshot
// dummies that have no display surface leave this field nil.
i_delegate_bridge_get_display_channel_broadcaster :: proc(self: ^I_Delegate_Bridge) -> ^I_Display {
        return self.get_display_channel_broadcaster(self)
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
        return self.get_resource_loader(self)
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
        return self.get_random(self, max, count, player, dice_type, annotation)
}
