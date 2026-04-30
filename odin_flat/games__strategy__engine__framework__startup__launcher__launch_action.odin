package game

Launch_Action :: struct {
	create_chat_model: proc(
		self: ^Launch_Action,
		chat_name: string,
		messengers: ^Messengers,
		client_network_bridge: ^Client_Network_Bridge,
	) -> ^Chat_Model,
	create_thread_messaging: proc(self: ^Launch_Action) -> ^Watcher_Thread_Messaging,
	get_auto_save_file: proc(self: ^Launch_Action) -> Path,
	get_auto_save_file_utils: proc(self: ^Launch_Action) -> ^Auto_Save_File_Utils,
	get_default_local_player_type: proc(self: ^Launch_Action) -> ^Player_Types_Type,
	get_fallback_connection: proc(self: ^Launch_Action, cancel_action: proc()) -> Maybe(^Server_Connection_Props),
}

// Java owners covered by this file:
//   - games.strategy.engine.framework.startup.launcher.LaunchAction

// Dispatch for the Java `LaunchAction#createChatModel(String, Messengers,
// ClientNetworkBridge)` interface method. Embedding structs install their
// own `create_chat_model` proc; this dispatch invokes it and returns nil
// when no override has been installed.
launch_action_create_chat_model :: proc(
	self: ^Launch_Action,
	chat_name: string,
	messengers: ^Messengers,
	client_network_bridge: ^Client_Network_Bridge,
) -> ^Chat_Model {
	if self == nil {
		return nil
	}
	if self.create_chat_model != nil {
		return self.create_chat_model(self, chat_name, messengers, client_network_bridge)
	}
	return nil
}

// Dispatch for the Java `LaunchAction#createThreadMessaging()` interface
// method. Embedding structs install their own `create_thread_messaging`
// proc; this dispatch invokes it and returns nil when no override has
// been installed.
launch_action_create_thread_messaging :: proc(self: ^Launch_Action) -> ^Watcher_Thread_Messaging {
	if self == nil {
		return nil
	}
	if self.create_thread_messaging != nil {
		return self.create_thread_messaging(self)
	}
	return nil
}

// Dispatch for the Java `LaunchAction#getAutoSaveFile()` interface method.
// Embedding structs install their own `get_auto_save_file` proc; this
// dispatch invokes it and returns an empty `Path` when no override has
// been installed.
launch_action_get_auto_save_file :: proc(self: ^Launch_Action) -> Path {
	if self == nil {
		return Path{}
	}
	if self.get_auto_save_file != nil {
		return self.get_auto_save_file(self)
	}
	return Path{}
}

// Dispatch for the Java `LaunchAction#getAutoSaveFileUtils()` interface
// method. Embedding structs install their own `get_auto_save_file_utils`
// proc; this dispatch invokes it and returns nil when no override has
// been installed.
launch_action_get_auto_save_file_utils :: proc(self: ^Launch_Action) -> ^Auto_Save_File_Utils {
	if self == nil {
		return nil
	}
	if self.get_auto_save_file_utils != nil {
		return self.get_auto_save_file_utils(self)
	}
	return nil
}

// Dispatch for the Java `LaunchAction#getDefaultLocalPlayerType()` interface
// method. Embedding structs install their own `get_default_local_player_type`
// proc; this dispatch invokes it and returns nil when no override has been
// installed.
launch_action_get_default_local_player_type :: proc(self: ^Launch_Action) -> ^Player_Types_Type {
	if self == nil {
		return nil
	}
	if self.get_default_local_player_type != nil {
		return self.get_default_local_player_type(self)
	}
	return nil
}

// Dispatch for the Java `LaunchAction#getFallbackConnection(Runnable)`
// interface method. Embedding structs install their own
// `get_fallback_connection` proc; this dispatch invokes it and returns
// an empty `Maybe` when no override has been installed.
launch_action_get_fallback_connection :: proc(
	self: ^Launch_Action,
	cancel_action: proc(),
) -> Maybe(^Server_Connection_Props) {
	if self == nil {
		return nil
	}
	if self.get_fallback_connection != nil {
		return self.get_fallback_connection(self, cancel_action)
	}
	return nil
}
