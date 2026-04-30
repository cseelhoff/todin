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

