package game

I_Game :: struct {
	get_data:       proc(self: ^I_Game) -> ^Game_Data,
	get_messengers: proc(self: ^I_Game) -> ^Messengers,
	get_vault:      proc(self: ^I_Game) -> ^Vault,
	is_game_over:   proc(self: ^I_Game) -> bool,
	set_display:    proc(self: ^I_Game, display: ^I_Display),
	set_resource_loader: proc(self: ^I_Game, resource_loader: ^Resource_Loader),
	set_sound_channel: proc(self: ^I_Game, sound: ^I_Sound),
}

// games.strategy.engine.framework.IGame#setSoundChannel(org.triplea.sound.ISound)
i_game_set_sound_channel :: proc(self: ^I_Game, sound: ^I_Sound) {
	self.set_sound_channel(self, sound)
}

IGame :: I_Game

// games.strategy.engine.framework.IGame#getData()
i_game_get_data :: proc(self: ^I_Game) -> ^Game_Data {
	return self.get_data(self)
}

// games.strategy.engine.framework.IGame#getMessengers()
i_game_get_messengers :: proc(self: ^I_Game) -> ^Messengers {
	return self.get_messengers(self)
}

// games.strategy.engine.framework.IGame#getVault()
i_game_get_vault :: proc(self: ^I_Game) -> ^Vault {
	return self.get_vault(self)
}

// games.strategy.engine.framework.IGame#isGameOver()
i_game_is_game_over :: proc(self: ^I_Game) -> bool {
	return self.is_game_over(self)
}

// games.strategy.engine.framework.IGame#setDisplay(games.strategy.engine.display.IDisplay)
i_game_set_display :: proc(self: ^I_Game, display: ^I_Display) {
	self.set_display(self, display)
}

// games.strategy.engine.framework.IGame#setResourceLoader(games.strategy.triplea.ResourceLoader)
i_game_set_resource_loader :: proc(self: ^I_Game, resource_loader: ^Resource_Loader) {
	self.set_resource_loader(self, resource_loader)
}

