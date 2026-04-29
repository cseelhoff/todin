package game

Game_To_Lobby_Connection :: struct {
	lobby_client:         ^Http_Lobby_Client,
	lobby_watcher_client: ^Lobby_Watcher_Client,
	web_socket:           ^Web_Socket,
	public_visible_ip:    ^Inet_Address,
}

