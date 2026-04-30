package game

Lobby_Watcher_Keep_Alive_Task :: struct {
	game_id:           string,
	game_id_setter:    proc(_: string),
	keep_alive_sender: proc(_: string) -> bool,
	game_poster:       proc() -> ^Game_Posting_Response,
}

make_Lobby_Watcher_Keep_Alive_Task :: proc(
	game_id: string,
	game_id_setter: proc(_: string),
	keep_alive_sender: proc(_: string) -> bool,
	game_poster: proc() -> ^Game_Posting_Response,
) -> ^Lobby_Watcher_Keep_Alive_Task {
	self := new(Lobby_Watcher_Keep_Alive_Task)
	self.game_id = game_id
	self.game_id_setter = game_id_setter
	self.keep_alive_sender = keep_alive_sender
	self.game_poster = game_poster
	return self
}
