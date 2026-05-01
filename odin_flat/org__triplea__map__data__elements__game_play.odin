package game

Game_Play :: struct {
	delegates: [dynamic]^Game_Play_Delegate,
	sequence:  ^Game_Play_Sequence,
	offset:    ^Game_Play_Offset,
}
// Java owners covered by this file:
//   - org.triplea.map.data.elements.GamePlay

game_play_get_delegates :: proc(self: ^Game_Play) -> [dynamic]^Game_Play_Delegate {
	return self.delegates
}

game_play_get_sequence :: proc(self: ^Game_Play) -> ^Game_Play_Sequence {
	return self.sequence
}

game_play_get_offset :: proc(self: ^Game_Play) -> ^Game_Play_Offset {
	return self.offset
}
