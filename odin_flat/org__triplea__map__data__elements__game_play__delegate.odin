package game

Game_Play_Delegate :: struct {
	name:       string,
	java_class: string,
	display:    string,
}

game_play_delegate_get_name :: proc(self: ^Game_Play_Delegate) -> string {
	return self.name
}

game_play_delegate_get_java_class :: proc(self: ^Game_Play_Delegate) -> string {
	return self.java_class
}

game_play_delegate_get_display :: proc(self: ^Game_Play_Delegate) -> string {
	return self.display
}

