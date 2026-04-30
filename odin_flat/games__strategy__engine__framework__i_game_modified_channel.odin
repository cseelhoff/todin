package game

I_Game_Modified_Channel :: struct {
	add_child_to_event:  proc(self: ^I_Game_Modified_Channel, text: string, rendering_data: rawptr),
	game_data_changed:   proc(self: ^I_Game_Modified_Channel, change: ^Change),
	shut_down:           proc(self: ^I_Game_Modified_Channel),
	start_history_event: proc(self: ^I_Game_Modified_Channel, event_name: string),
	start_history_event_with_data: proc(self: ^I_Game_Modified_Channel, event_name: string, rendering_data: rawptr),
	step_changed: proc(self: ^I_Game_Modified_Channel, step_name: string, delegate_name: string, player: ^Game_Player, round: i32, display_name: string, load_from_save: bool),
}

// games.strategy.engine.framework.IGameModifiedChannel#stepChanged(java.lang.String,java.lang.String,games.strategy.engine.data.GamePlayer,int,java.lang.String,boolean)
i_game_modified_channel_step_changed :: proc(self: ^I_Game_Modified_Channel, step_name: string, delegate_name: string, player: ^Game_Player, round: i32, display_name: string, load_from_save: bool) {
	self.step_changed(self, step_name, delegate_name, player, round, display_name, load_from_save)
}

// games.strategy.engine.framework.IGameModifiedChannel#startHistoryEvent(java.lang.String,java.lang.Object)
i_game_modified_channel_start_history_event_with_data :: proc(self: ^I_Game_Modified_Channel, event_name: string, rendering_data: rawptr) {
	self.start_history_event_with_data(self, event_name, rendering_data)
}

// games.strategy.engine.framework.IGameModifiedChannel#startHistoryEvent(java.lang.String)
i_game_modified_channel_start_history_event :: proc(self: ^I_Game_Modified_Channel, event_name: string) {
	self.start_history_event(self, event_name)
}

// games.strategy.engine.framework.IGameModifiedChannel#addChildToEvent(java.lang.String,java.lang.Object)
i_game_modified_channel_add_child_to_event :: proc(self: ^I_Game_Modified_Channel, text: string, rendering_data: rawptr) {
	self.add_child_to_event(self, text, rendering_data)
}

// games.strategy.engine.framework.IGameModifiedChannel#gameDataChanged(games.strategy.engine.data.Change)
i_game_modified_channel_game_data_changed :: proc(self: ^I_Game_Modified_Channel, change: ^Change) {
	self.game_data_changed(self, change)
}

// games.strategy.engine.framework.IGameModifiedChannel#shutDown()
i_game_modified_channel_shut_down :: proc(self: ^I_Game_Modified_Channel) {
	self.shut_down(self)
}

