package game

// Java owner: games.strategy.engine.chat.ChatPlayerListener (interface)
//
// Pure-callback interface modeled with proc-typed fields installed by
// concrete implementers. Dispatch procs (`chat_player_listener_*`) are
// the public entry points.

Chat_Player_Listener :: struct {
	update_player_list: proc(self: ^Chat_Player_Listener, players: []^Chat_Participant),
}

// games.strategy.engine.chat.ChatPlayerListener#updatePlayerList(java.util.Collection)
chat_player_listener_update_player_list :: proc(self: ^Chat_Player_Listener, players: []^Chat_Participant) {
	self.update_player_list(self, players)
}

