package game

Game_Object_Stream_Factory :: struct {
	game_data: ^Game_Data,
}

make_Game_Object_Stream_Factory :: proc(game_data: ^Game_Data) -> Game_Object_Stream_Factory {
	return Game_Object_Stream_Factory{game_data = game_data}
}
