package game

Server_Model_View :: struct {
	disable_player:     proc(self: ^Server_Model_View, player_name: string),
	enable_player:      proc(self: ^Server_Model_View, player_name: string),
	get_game_options:   proc(self: ^Server_Model_View) -> []u8,
	get_player_listing: proc(self: ^Server_Model_View) -> ^Player_Listing,
}

// games.strategy.engine.framework.startup.mc.IServerStartupRemote$ServerModelView#disablePlayer(java.lang.String)
i_server_startup_remote_server_model_view_disable_player :: proc(self: ^Server_Model_View, player_name: string) {
	self.disable_player(self, player_name)
}

// games.strategy.engine.framework.startup.mc.IServerStartupRemote$ServerModelView#enablePlayer(java.lang.String)
i_server_startup_remote_server_model_view_enable_player :: proc(self: ^Server_Model_View, player_name: string) {
	self.enable_player(self, player_name)
}

// games.strategy.engine.framework.startup.mc.IServerStartupRemote$ServerModelView#getGameOptions()
i_server_startup_remote_server_model_view_get_game_options :: proc(self: ^Server_Model_View) -> []u8 {
	return self.get_game_options(self)
}

// games.strategy.engine.framework.startup.mc.IServerStartupRemote$ServerModelView#getPlayerListing()
i_server_startup_remote_server_model_view_get_player_listing :: proc(self: ^Server_Model_View) -> ^Player_Listing {
	return self.get_player_listing(self)
}

