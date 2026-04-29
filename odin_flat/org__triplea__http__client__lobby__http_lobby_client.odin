package game

Http_Lobby_Client :: struct {
	lobby_uri:                  string,
	api_key:                    ^Api_Key,
	moderator_toolbox_client:   ^Moderator_Toolbox_Client,
	moderator_lobby_client:     ^Moderator_Lobby_Client,
	user_account_client:        ^User_Account_Client,
	remote_actions_client:      ^Remote_Actions_Client,
	player_lobby_actions_client: ^Player_Lobby_Actions_Client,
}
// Java owners covered by this file:
//   - org.triplea.http.client.lobby.HttpLobbyClient

