package game

Dummy_Delegate_Bridge :: struct {
	random_source:    ^Plain_Random_Source,
	display:          ^Headless_Display,
	sound_channel:    ^Headless_Sound_Channel,
	attacking_player: ^Dummy_Player,
	defending_player: ^Dummy_Player,
	attacker:         ^Game_Player,
	writer:           ^Delegate_History_Writer,
	all_changes:      ^Composite_Change,
	game_data:        ^Game_Data,
	battle:           ^Must_Fight_Battle,
	tuv_calculator:   ^Tuv_Costs_Calculator,
}

dummy_delegate_bridge_get_battle :: proc(self: ^Dummy_Delegate_Bridge) -> ^Must_Fight_Battle {
	return self.battle
}

dummy_delegate_bridge_get_data :: proc(self: ^Dummy_Delegate_Bridge) -> ^Game_Data {
	return self.game_data
}

dummy_delegate_bridge_get_display_channel_broadcaster :: proc(self: ^Dummy_Delegate_Bridge) -> ^Headless_Display {
	return self.display
}

dummy_delegate_bridge_get_history_writer :: proc(self: ^Dummy_Delegate_Bridge) -> ^Delegate_History_Writer {
	return self.writer
}

dummy_delegate_bridge_get_remote_player :: proc(self: ^Dummy_Delegate_Bridge, game_player: ^Game_Player) -> ^Dummy_Player {
	if game_player == self.attacker {
		return self.attacking_player
	}
	return self.defending_player
}

dummy_delegate_bridge_get_sound_channel_broadcaster :: proc(self: ^Dummy_Delegate_Bridge) -> ^Headless_Sound_Channel {
	return self.sound_channel
}

dummy_delegate_bridge_set_battle :: proc(self: ^Dummy_Delegate_Bridge, battle: ^Must_Fight_Battle) {
	self.battle = battle
}

dummy_delegate_bridge_get_costs_for_tuv :: proc(
	self: ^Dummy_Delegate_Bridge,
	player: ^Game_Player,
) -> map[^Unit_Type]i32 {
	return tuv_costs_calculator_get_costs_for_tuv(self.tuv_calculator, player)
}
