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

// games.strategy.engine.framework.AbstractGame#lambda$setDisplay$0(games.strategy.engine.display.IDisplay,games.strategy.engine.display.IDisplay$BombingResultsMessage)
abstract_game_lambda_set_display_0 :: proc(display: ^I_Display, message: ^I_Display_Bombing_Results_Message) {
	i_display_bombing_results_message_accept(message, display)
}

// games.strategy.engine.framework.AbstractGame#lambda$setDisplay$2(games.strategy.engine.display.IDisplay,games.strategy.engine.display.IDisplay$NotifyUnitsRetreatingMessage)
abstract_game_lambda_set_display_2 :: proc(self: ^Abstract_Game, display: ^I_Display, message: ^I_Display_Notify_Units_Retreating_Message) {
	i_display_notify_units_retreating_message_accept(message, display, game_data_get_units(self.game_data))
}

// games.strategy.engine.framework.AbstractGame#lambda$setDisplay$3(games.strategy.engine.display.IDisplay,games.strategy.engine.display.IDisplay$NotifyDiceMessage)
abstract_game_lambda_set_display_3 :: proc(display: ^I_Display, message: ^Notify_Dice_Message) {
	notify_dice_message_accept(message, display)
}

// games.strategy.engine.framework.AbstractGame#lambda$setDisplay$4(games.strategy.engine.display.IDisplay,games.strategy.engine.display.IDisplay$DisplayShutdownMessage)
abstract_game_lambda_set_display_4 :: proc(display: ^I_Display, message: ^Display_Shutdown_Message) {
	i_display_display_shutdown_message_accept(message, display)
}

// games.strategy.engine.framework.AbstractGame#lambda$setDisplay$5(games.strategy.engine.display.IDisplay,games.strategy.engine.display.IDisplay$GoToBattleStepMessage)
abstract_game_lambda_set_display_5 :: proc(display: ^I_Display, message: ^Go_To_Battle_Step_Message) {
	i_display_go_to_battle_step_message_accept(message, display)
}

// games.strategy.engine.framework.AbstractGame#setSoundChannel(org.triplea.sound.ISound)
abstract_game_set_sound_channel :: proc(self: ^Abstract_Game, sound_channel: ^I_Sound) {
	if self.sound == sound_channel {
		return
	}
	if self.sound != nil {
		messengers_unregister_channel_subscriber(self.messengers, self.sound, abstract_game_get_sound_channel())
	}
	if sound_channel != nil {
		messengers_register_channel_subscriber(self.messengers, sound_channel, abstract_game_get_sound_channel())
	}
	self.sound = sound_channel
}

// games.strategy.engine.framework.AbstractGame#setDisplay(games.strategy.engine.display.IDisplay)
abstract_game_set_display :: proc(self: ^Abstract_Game, display: ^I_Display) {
	if self.display == display {
		return
	}
	if self.display != nil {
		messengers_unregister_channel_subscriber(self.messengers, self.display, abstract_game_get_display_channel())
		i_display_shut_down(self.display)
	}
	if display != nil {
		messengers_register_channel_subscriber(self.messengers, display, abstract_game_get_display_channel())

		noop :: proc(msg: rawptr) {}
		client_network_bridge_add_listener(self.client_network_bridge, nil, noop)
		client_network_bridge_add_listener(self.client_network_bridge, nil, noop)
		client_network_bridge_add_listener(self.client_network_bridge, nil, noop)
		client_network_bridge_add_listener(self.client_network_bridge, nil, noop)
		client_network_bridge_add_listener(self.client_network_bridge, nil, noop)
		client_network_bridge_add_listener(self.client_network_bridge, nil, noop)
	}
	self.display = display
}

