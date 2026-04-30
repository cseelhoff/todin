package game

Lobby_Watcher_Keep_Alive_Task :: struct {
	game_id:           string,
	game_id_setter:    proc(_: string),
	keep_alive_sender: proc(_: string) -> bool,
	game_poster:       proc() -> ^Game_Posting_Response,
}
