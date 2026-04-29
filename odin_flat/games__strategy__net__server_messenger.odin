package game

Server_Messenger :: struct {
	using parent:             I_Server_Messenger,
	using nio_listener:       Nio_Socket_Listener,
	new_node_lock:            rawptr,
	acceptor_selector:        ^Selector,
	socket_channel:           ^Server_Socket_Channel,
	node:                     ^Node,
	shutdown:                 bool,
	nio_socket:               ^Nio_Socket,
	listeners:                [dynamic]^I_Message_Listener,
	connection_listeners:     [dynamic]^I_Connection_Change_Listener,
	accept_new_connection:    bool,
	login_validator:          ^I_Login_Validator,
	node_to_channel:          map[^I_Node]^Socket_Channel,
	channel_to_node:          map[^Socket_Channel]^I_Node,
	node_join_order:          [dynamic]^I_Node,
	cached_mac_addresses:     map[^User_Name]string,
	mini_banned_ip_addresses: map[string]struct{},
	game_to_lobby_connection: ^Game_To_Lobby_Connection,
}

