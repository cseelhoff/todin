package game

// Java owner: games.strategy.engine.framework.startup.mc.IClientChannel
//
// Pure-callback interface (extends IChannelSubscriber). Each abstract
// method is modeled as a proc-typed field; concrete implementers install
// their function at construction time. Dispatch procs
// (`i_client_channel_*`) are the public entry points.

I_Client_Channel :: struct {
	done_selecting_players: proc(self: ^I_Client_Channel, game_data: []u8, players_to_node: map[string]^I_Node),
	game_reset:             proc(self: ^I_Client_Channel),
	player_listing_changed: proc(self: ^I_Client_Channel, listing: ^Player_Listing),
}

// Java: RemoteName CHANNEL_NAME =
//   new RemoteName("games.strategy.engine.framework.ui.IClientChannel.CHANNEL", IClientChannel.class);
i_client_channel_channel_name :: proc() -> ^Remote_Name {
	return remote_name_new(
		"games.strategy.engine.framework.ui.IClientChannel.CHANNEL",
		class_new("games.strategy.engine.framework.startup.mc.IClientChannel", "IClientChannel"),
	)
}

// games.strategy.engine.framework.startup.mc.IClientChannel#doneSelectingPlayers(byte[],java.util.Map)
i_client_channel_done_selecting_players :: proc(self: ^I_Client_Channel, game_data: []u8, players_to_node: map[string]^I_Node) {
	self.done_selecting_players(self, game_data, players_to_node)
}

// games.strategy.engine.framework.startup.mc.IClientChannel#gameReset()
i_client_channel_game_reset :: proc(self: ^I_Client_Channel) {
	self.game_reset(self)
}

// games.strategy.engine.framework.startup.mc.IClientChannel#playerListingChanged(games.strategy.engine.framework.message.PlayerListing)
i_client_channel_player_listing_changed :: proc(self: ^I_Client_Channel, listing: ^Player_Listing) {
	self.player_listing_changed(self, listing)
}

