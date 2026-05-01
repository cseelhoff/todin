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

abstract_game_get_data :: proc(self: ^Abstract_Game) -> ^Game_Data {
	return self.game_data
}

abstract_game_get_messengers :: proc(self: ^Abstract_Game) -> ^Messengers {
	return self.messengers
}

abstract_game_is_game_over :: proc(self: ^Abstract_Game) -> bool {
	return self.is_game_over
}

abstract_game_set_resource_loader :: proc(self: ^Abstract_Game, resource_loader: ^Resource_Loader) {
	assert(resource_loader != nil, "ResourceLoader needs to be non-null")
	self.resource_loader = resource_loader
}

ABSTRACT_GAME_DISPLAY_CHANNEL :: "games.strategy.engine.framework.AbstractGame.DISPLAY_CHANNEL"
ABSTRACT_GAME_SOUND_CHANNEL :: "games.strategy.engine.framework.AbstractGame.SOUND_CHANNEL"

abstract_game_get_display_channel :: proc() -> ^Remote_Name {
	return remote_name_new(ABSTRACT_GAME_DISPLAY_CHANNEL, class_new("games.strategy.engine.display.IDisplay", "IDisplay"))
}

abstract_game_get_sound_channel :: proc() -> ^Remote_Name {
	return remote_name_new(ABSTRACT_GAME_SOUND_CHANNEL, class_new("org.triplea.sound.ISound", "ISound"))
}

