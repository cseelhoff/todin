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
