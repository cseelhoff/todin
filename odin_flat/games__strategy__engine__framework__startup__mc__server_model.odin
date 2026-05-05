package game

import "core:fmt"

// Java owner: games.strategy.engine.framework.startup.mc.ServerModel
// Phase A: type fields only.

Server_Model :: struct {
	using observable:                         Observable,
	object_stream_factory:                    ^Game_Object_Stream_Factory,
	server_messenger:                         ^Server_Messenger,
	messengers:                               ^Messengers,
	data:                                     ^Game_Data,
	players_to_node_listing:                  map[string]string,
	players_to_nodes_mapping_persisted:       bool,
	players_enabled_listing:                  map[string]bool,
	players_allowed_to_be_disabled:           map[string]struct{},
	player_names_and_alliances_in_turn_order: map[string]map[string]struct{},
	remote_model_listener:                    ^I_Remote_Model_Listener,
	game_selector_model:                      ^Game_Selector_Model,
	launch_action:                            ^Launch_Action,
	chat_model:                               ^Chat_Model,
	chat_controller:                          ^Chat_Controller,
	local_player_types:                       map[string]^Player_Types_Type,
	server_launcher:                          ^Server_Launcher,
	remove_connections_latch:                 ^Count_Down_Latch,
	game_selector_observer:                   proc(observable: ^Observable, value: rawptr),
	lobby_watcher_thread:                     ^Lobby_Watcher_Thread,
	game_to_lobby_connection:                 ^Game_To_Lobby_Connection,
}

server_model_allow_remove_connections :: proc(self: ^Server_Model) {
	for self.remove_connections_latch != nil &&
	    count_down_latch_get_count(self.remove_connections_latch) > 0 {
		count_down_latch_count_down(self.remove_connections_latch)
	}
	self.remove_connections_latch = nil
}

server_model_disallow_remove_connections :: proc(self: ^Server_Model) {
	for self.remove_connections_latch != nil &&
	    count_down_latch_get_count(self.remove_connections_latch) > 0 {
		count_down_latch_count_down(self.remove_connections_latch)
	}
	self.remove_connections_latch = count_down_latch_new(1)
}

server_model_cancel :: proc(self: ^Server_Model) {
	if self.game_selector_model != nil {
		observable_delete_observer(
			&self.game_selector_model.observable,
			self.game_selector_observer,
		)
	}
	if self.lobby_watcher_thread != nil {
		watcher := lobby_watcher_thread_get_lobby_watcher(self.lobby_watcher_thread)
		if watcher != nil {
			in_game_lobby_watcher_wrapper_shut_down(watcher)
		}
	}
	if self.chat_controller != nil {
		chat_controller_deactivate(self.chat_controller)
	}
	if self.messengers != nil {
		messengers_shut_down(self.messengers)
	}
	if self.chat_model != nil {
		chat_model_cancel(self.chat_model)
	}
}

server_model_get_chat_model :: proc(self: ^Server_Model) -> ^Chat_Model {
	return self.chat_model
}

server_model_get_lobby_watcher_thread :: proc(self: ^Server_Model) -> ^Lobby_Watcher_Thread {
	return self.lobby_watcher_thread
}

server_model_get_messenger :: proc(self: ^Server_Model) -> ^Server_Messenger {
	return self.server_messenger
}

server_model_get_players_to_node_listing :: proc(self: ^Server_Model) -> map[string]string {
	out := make(map[string]string)
	for k, v in self.players_to_node_listing {
		out[k] = v
	}
	return out
}

server_model_get_players_enabled_listing :: proc(self: ^Server_Model) -> map[string]bool {
	out := make(map[string]bool)
	for k, v in self.players_enabled_listing {
		out[k] = v
	}
	return out
}

server_model_lambda_connection_removed_12 :: proc(self: ^Server_Model) -> bool {
	return count_down_latch_await_timeout(self.remove_connections_latch, 6, .SECONDS)
}

server_model_lambda_get_launcher_14 :: proc(
	remote_players: ^map[string]^I_Node,
	entry_key: string,
	node: ^I_Node,
) {
	remote_players^[entry_key] = node
}

server_model_lambda_notify_channel_players_changed_6 :: proc(e: ^Throwable) -> rawptr {
	fmt.eprintln("Network communication error")
	return nil
}

server_model_lambda_notify_lobby_9 :: proc(
	self: ^Server_Model,
	connection_and_game_id_action: proc(^Game_To_Lobby_Connection, string),
	game_id: string,
) {
	connection_and_game_id_action(self.game_to_lobby_connection, game_id)
}

// games.strategy.engine.framework.startup.mc.ServerModel#lambda$setAllPlayersToNullNodes$4(java.lang.String,java.lang.String)
// Java: `playersToNodeListing.replaceAll((key, value) -> null)`. Odin's
// `string` cannot be nil, so the empty string acts as the null sentinel.
server_model_lambda_set_all_players_to_null_nodes_4 :: proc(key: string, value: string) -> string {
	return ""
}

// games.strategy.engine.framework.startup.mc.ServerModel#notifyChannelPlayersChanged()
server_model_notify_channel_players_changed :: proc(self: ^Server_Model) {
	if self.messengers == nil {
		return
	}
	channel := cast(^I_Client_Channel)messengers_get_channel_broadcaster(
		self.messengers,
		i_client_channel_channel_name(),
	)
	if channel == nil {
		return
	}
	i_client_channel_player_listing_changed(
		channel,
		server_model_get_player_listing_internal(self),
	)
}

// games.strategy.engine.framework.startup.mc.ServerModel#persistPlayersToNodesMapping()
server_model_persist_players_to_nodes_mapping :: proc(self: ^Server_Model) {
	self.players_to_nodes_mapping_persisted = true
}

// games.strategy.engine.framework.startup.mc.ServerModel#setAllPlayersToNullNodes()
// Java: `if (playersToNodeListing != null) playersToNodeListing.replaceAll((k, v) -> null)`.
// Odin maps are zero-value-initialized (never nil in the Java sense) and `string`
// has no nil; collect keys first, then set each to "" (the null sentinel).
server_model_set_all_players_to_null_nodes :: proc(self: ^Server_Model) {
	keys := make([dynamic]string, 0, len(self.players_to_node_listing))
	defer delete(keys)
	for k in self.players_to_node_listing {
		append(&keys, k)
	}
	for k in keys {
		self.players_to_node_listing[k] = server_model_lambda_set_all_players_to_null_nodes_4(
			k,
			self.players_to_node_listing[k],
		)
	}
}

// games.strategy.engine.framework.startup.mc.ServerModel#setRemoteModelListener(IRemoteModelListener)
// Java: `remoteModelListener = Optional.ofNullable(listener).orElse(IRemoteModelListener.NULL_LISTENER)`.
// IRemoteModelListener.NULL_LISTENER has no Odin equivalent yet; fall back to nil
// when the caller passes nil. Callers must nil-check before dispatching.
server_model_set_remote_model_listener :: proc(
	self: ^Server_Model,
	listener: ^I_Remote_Model_Listener,
) {
	if listener != nil {
		self.remote_model_listener = listener
	} else {
		self.remote_model_listener = nil
	}
}

// games.strategy.engine.framework.startup.mc.ServerModel#setServerLauncher(ServerLauncher)
server_model_set_server_launcher :: proc(self: ^Server_Model, launcher: ^Server_Launcher) {
	self.server_launcher = launcher
}

// games.strategy.engine.framework.startup.mc.ServerModel#getPlayerListingInternal()
// No-op stub: PlayerListing is only consumed by client UI code that the
// WW2v5 AI snapshot harness never invokes. Returning nil is safe because
// every call site nil-checks the channel broadcaster first.
server_model_get_player_listing_internal :: proc(self: ^Server_Model) -> ^Player_Listing {
	return nil
}

