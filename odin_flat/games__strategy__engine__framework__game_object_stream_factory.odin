package game

Game_Object_Stream_Factory :: struct {
	game_data: ^Game_Data,
}

make_Game_Object_Stream_Factory :: proc(game_data: ^Game_Data) -> Game_Object_Stream_Factory {
	return Game_Object_Stream_Factory{game_data = game_data}
}

game_object_stream_factory_get_data :: proc(self: ^Game_Object_Stream_Factory) -> ^Game_Data {
	return self.game_data
}

game_object_stream_factory_set_data :: proc(self: ^Game_Object_Stream_Factory, data: ^Game_Data) {
	self.game_data = data
}
