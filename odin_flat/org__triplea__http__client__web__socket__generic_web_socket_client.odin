package game

Generic_Web_Socket_Client_Message_Listener :: struct {
	message_type: ^Message_Type,
	listener:     proc(rawptr, rawptr),
	listener_ctx: rawptr,
}

Generic_Web_Socket_Client :: struct {
	connection_closed_listeners:         [dynamic]proc(rawptr),
	connection_closed_listener_ctxs:     [dynamic]rawptr,
	connection_terminated_listeners:     [dynamic]proc(rawptr, string),
	connection_terminated_listener_ctxs: [dynamic]rawptr,
	websocket_uri:                       string,
	error_handler:                       proc(rawptr, string),
	error_handler_ctx:                   rawptr,
	web_socket_connection_factory:       proc(rawptr, string) -> ^Web_Socket_Connection,
	web_socket_connection_factory_ctx:   rawptr,
	web_socket_connection:               ^Web_Socket_Connection,
	listeners:                           map[^Generic_Web_Socket_Client_Message_Listener]struct{},
}
