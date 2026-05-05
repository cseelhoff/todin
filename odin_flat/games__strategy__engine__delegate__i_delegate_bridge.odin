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
        send_message:             proc(self: ^I_Delegate_Bridge, msg: ^Web_Socket_Message),
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
