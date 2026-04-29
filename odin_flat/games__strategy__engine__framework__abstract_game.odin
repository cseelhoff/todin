package game

Abstract_Game :: struct {
	game_data:            ^Game_Data,
	messengers:           ^Messengers,
	is_game_over:         bool,
	vault:                ^Vault,
	first_run:            bool,
	game_modified_channel: ^I_Game_Modified_Channel,
	game_players:         map[^Game_Player]^Player,
	player_manager:       ^Player_Manager,
	client_network_bridge: ^Client_Network_Bridge,
	display:              ^I_Display,
	sound:                ^I_Sound,
	resource_loader:      ^Resource_Loader,
}
// Java owners covered by this file:
//   - games.strategy.engine.framework.AbstractGame

