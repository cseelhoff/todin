package game

Step_History_Serializer :: struct {
	using serialization_writer: Serialization_Writer,
	step_name:     string,
	delegate_name: string,
	game_player:   ^Game_Player,
	display_name:  string,
}
