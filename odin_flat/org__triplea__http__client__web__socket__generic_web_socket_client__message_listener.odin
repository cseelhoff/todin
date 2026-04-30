package game

Generic_Web_Socket_Client_Message_Listener :: struct {
	message_type: ^Message_Type,
	listener:     proc(rawptr, rawptr),
	listener_ctx: rawptr,
}

