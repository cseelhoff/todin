package game

Generic_Web_Socket_Client_Generic_Web_Socket_Client_Builder :: struct {
	websocket_uri:     string,
	error_handler:     proc(rawptr, string),
	error_handler_ctx: rawptr,
	headers:           map[string]string,
}

