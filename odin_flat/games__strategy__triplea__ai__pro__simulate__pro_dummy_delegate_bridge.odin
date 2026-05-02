package game

Pro_Dummy_Delegate_Bridge :: struct {
	random_source: Plain_Random_Source,
	display:       ^Headless_Display,
	sound_channel: ^Headless_Sound_Channel,
	player:        ^Game_Player,
	pro_ai:        ^Abstract_Pro_Ai,
	writer:        ^Delegate_History_Writer,
	game_data:     ^Game_Data,
	all_changes:   ^Composite_Change,
}

pro_dummy_delegate_bridge_new :: proc(ai: ^Abstract_Pro_Ai, player: ^Game_Player, game_data: ^Game_Data) -> ^Pro_Dummy_Delegate_Bridge {
	self := new(Pro_Dummy_Delegate_Bridge)
	self.random_source = plain_random_source_new()^
	self.display = headless_display_new()
	self.sound_channel = headless_sound_channel_new()
	self.writer = delegate_history_writer_create_no_op_implementation()
	self.all_changes = composite_change_new()
	self.pro_ai = ai
	self.game_data = game_data
	self.player = player
	return self
}

pro_dummy_delegate_bridge_get_data :: proc(self: ^Pro_Dummy_Delegate_Bridge) -> ^Game_Data {
	return self.game_data
}

pro_dummy_delegate_bridge_get_game_player :: proc(self: ^Pro_Dummy_Delegate_Bridge) -> ^Game_Player {
	return self.player
}

pro_dummy_delegate_bridge_get_history_writer :: proc(self: ^Pro_Dummy_Delegate_Bridge) -> ^Delegate_History_Writer {
	return self.writer
}

pro_dummy_delegate_bridge_get_remote_player :: proc(self: ^Pro_Dummy_Delegate_Bridge, game_player: ^Game_Player) -> ^Abstract_Pro_Ai {
	return self.pro_ai
}

pro_dummy_delegate_bridge_get_sound_channel_broadcaster :: proc(self: ^Pro_Dummy_Delegate_Bridge) -> ^Headless_Sound_Channel {
	return self.sound_channel
}
