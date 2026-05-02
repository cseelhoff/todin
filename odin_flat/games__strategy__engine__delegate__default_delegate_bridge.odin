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
