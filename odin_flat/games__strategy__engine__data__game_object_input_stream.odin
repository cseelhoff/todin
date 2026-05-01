package game

import "core:io"

Game_Object_Input_Stream :: struct {
	using object_input_stream: Object_Input_Stream,
	data_source:  ^Game_Object_Stream_Factory,
	input:        io.Reader,
}

make_Game_Object_Input_Stream :: proc(factory: ^Game_Object_Stream_Factory, input: io.Reader) -> ^Game_Object_Input_Stream {
	stream := new(Game_Object_Input_Stream)
	stream.data_source = factory
	stream.input = input
	return stream
}

game_object_input_stream_get_data :: proc(self: ^Game_Object_Input_Stream) -> ^Game_Data {
	return game_object_stream_factory_get_data(self.data_source)
}
