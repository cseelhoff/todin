package game

Web_Socket_Connection :: struct {
	listener:           ^Web_Socket_Connection_Listener,
	queued_messages:    [dynamic]string,
	headers:            map[string]string,
	connection_is_open: bool,
	http_client:        ^Http_Client,
	server_uri:         ^Uri,
	closed:             bool,
	client:             ^Web_Socket,
	internal_listener:  ^Web_Socket_Connection_Internal_Web_Socket_Listener,
	ping_sender:        ^Scheduled_Timer,
}

