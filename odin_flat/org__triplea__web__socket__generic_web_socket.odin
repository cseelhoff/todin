package game

Generic_Web_Socket :: struct {
	web_socket_messaging_bus: ^Web_Socket_Messaging_Bus,
	ban_check:                proc(addr: ^Inet_Address) -> bool,
	message_sender:           ^Message_Sender,
}

