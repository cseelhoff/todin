package game

import "core:io"

Game_Object_Output_Stream :: struct {
	using object_output_stream: Object_Output_Stream,
	output: io.Writer,
}

make_Game_Object_Output_Stream :: proc(output: io.Writer) -> ^Game_Object_Output_Stream {
	stream := new(Game_Object_Output_Stream)
	stream.output = output
	return stream
}

game_object_output_stream_replace_object :: proc(self: ^Game_Object_Output_Stream, obj: ^Named) -> rawptr {
	if obj != nil && game_object_stream_data_can_serialize(obj) {
		return rawptr(game_object_stream_data_new(obj))
	}
	return rawptr(obj)
}

