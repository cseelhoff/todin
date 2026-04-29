package game

Game_Object_Input_Stream :: struct {
	using parent: Object_Input_Stream,
	data_source:  ^Game_Object_Stream_Factory,
}
