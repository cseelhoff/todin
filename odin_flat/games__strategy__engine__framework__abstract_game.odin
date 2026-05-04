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

// games.strategy.engine.framework.AbstractGame#lambda$setDisplay$1(games.strategy.engine.display.IDisplay,games.strategy.engine.display.IDisplay$NotifyRetreatMessage)
abstract_game_lambda_set_display_1 :: proc(self: ^Abstract_Game, display: ^I_Display, message: ^Notify_Retreat_Message) {
	i_display_notify_retreat_message_accept(message, display, game_data_get_player_list(self.game_data))
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

// I_Game adapter for Abstract_Game.
// Java's `AbstractGame implements IGame` is modeled in Odin by an
// adapter struct whose first field is the I_Game callback table; a
// pointer to this adapter is type-pun safe with `^I_Game`. The adapter
// retains a back-reference to its owning Abstract_Game so the
// callbacks can dispatch to the corresponding `abstract_game_*` procs.
Abstract_Game_I_Game_View :: struct {
	using i_game: I_Game,
	target:       ^Abstract_Game,
}

abstract_game_view_get_data :: proc(self: ^I_Game) -> ^Game_Data {
	view := cast(^Abstract_Game_I_Game_View)self
	return abstract_game_get_data(view.target)
}

abstract_game_view_get_messengers :: proc(self: ^I_Game) -> ^Messengers {
	view := cast(^Abstract_Game_I_Game_View)self
	return abstract_game_get_messengers(view.target)
}

abstract_game_view_get_vault :: proc(self: ^I_Game) -> ^Vault {
	view := cast(^Abstract_Game_I_Game_View)self
	return view.target.vault
}

abstract_game_view_is_game_over :: proc(self: ^I_Game) -> bool {
	view := cast(^Abstract_Game_I_Game_View)self
	return abstract_game_is_game_over(view.target)
}

abstract_game_view_set_display :: proc(self: ^I_Game, display: ^I_Display) {
	view := cast(^Abstract_Game_I_Game_View)self
	abstract_game_set_display(view.target, display)
}

abstract_game_view_set_resource_loader :: proc(self: ^I_Game, resource_loader: ^Resource_Loader) {
	view := cast(^Abstract_Game_I_Game_View)self
	abstract_game_set_resource_loader(view.target, resource_loader)
}

abstract_game_view_set_sound_channel :: proc(self: ^I_Game, sound_channel: ^I_Sound) {
	view := cast(^Abstract_Game_I_Game_View)self
	abstract_game_set_sound_channel(view.target, sound_channel)
}

abstract_game_as_i_game :: proc(self: ^Abstract_Game) -> ^I_Game {
	view := new(Abstract_Game_I_Game_View)
	view.target              = self
	view.get_data            = abstract_game_view_get_data
	view.get_messengers      = abstract_game_view_get_messengers
	view.get_vault           = abstract_game_view_get_vault
	view.is_game_over        = abstract_game_view_is_game_over
	view.set_display         = abstract_game_view_set_display
	view.set_resource_loader = abstract_game_view_set_resource_loader
	view.set_sound_channel   = abstract_game_view_set_sound_channel
	return cast(^I_Game)view
}

// games.strategy.engine.framework.AbstractGame#setupLocalPlayers(java.util.Set)
//
// Java:
//   private void setupLocalPlayers(final Set<Player> localPlayers) {
//     final PlayerList playerList = gameData.getPlayerList();
//     for (final Player gp : localPlayers) {
//       final GamePlayer player = playerList.getPlayerId(gp.getName());
//       gamePlayers.put(player, gp);
//       gp.initialize(new PlayerBridge(this), player);
//       final RemoteName descriptor = ServerGame.getRemoteName(gp.getGamePlayer());
//       messengers.registerRemote(gp, descriptor);
//     }
//   }
abstract_game_setup_local_players :: proc(self: ^Abstract_Game, local_players: map[^Player]struct{}) {
	player_list := game_data_get_player_list(self.game_data)
	i_game := abstract_game_as_i_game(self)
	for gp in local_players {
		player := player_list_get_player_id(player_list, player_get_name(gp))
		self.game_players[player] = gp
		player_initialize(gp, player_bridge_new(i_game), player)
		descriptor := server_game_get_remote_name_for_player(player_get_game_player(gp))
		messengers_register_remote(self.messengers, gp, descriptor)
	}
}

// games.strategy.engine.framework.AbstractGame#<init>(games.strategy.engine.data.GameData,java.util.Set,java.util.Map,games.strategy.net.Messengers,games.strategy.net.websocket.ClientNetworkBridge)
//
// Java:
//   AbstractGame(
//       final GameData data,
//       final Set<Player> gamePlayers,
//       final Map<String, INode> remotePlayerMapping,
//       final Messengers messengers,
//       final ClientNetworkBridge clientNetworkBridge) {
//     gameData = data;
//     this.messengers = messengers;
//     this.clientNetworkBridge = clientNetworkBridge;
//     vault = new Vault(messengers);
//     final Map<String, INode> allPlayers = new HashMap<>(remotePlayerMapping);
//     for (final Player player : gamePlayers) {
//       allPlayers.put(player.getName(), messengers.getLocalNode());
//     }
//     playerManager = new PlayerManager(allPlayers);
//     setupLocalPlayers(gamePlayers);
//   }
abstract_game_new :: proc(
	data: ^Game_Data,
	game_players: map[^Player]struct{},
	remote_player_mapping: map[string]^I_Node,
	messengers: ^Messengers,
	client_network_bridge: ^Client_Network_Bridge,
) -> ^Abstract_Game {
	self := new(Abstract_Game)
	self.game_data = data
	self.messengers = messengers
	self.client_network_bridge = client_network_bridge
	self.is_game_over = false
	self.first_run = true
	self.vault = vault_new(messengers.channel_messenger)
	self.game_players = make(map[^Game_Player]^Player)

	all_players: map[string]^I_Node
	for k, v in remote_player_mapping {
		all_players[k] = v
	}
	for player in game_players {
		all_players[player_get_name(player)] = messengers_get_local_node(messengers)
	}
	pm := make_Player_Manager(all_players)
	self.player_manager = new(Player_Manager)
	self.player_manager^ = pm

	abstract_game_setup_local_players(self, game_players)
	return self
}

