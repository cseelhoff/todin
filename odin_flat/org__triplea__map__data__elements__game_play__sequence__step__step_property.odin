package game

Game_Play_Sequence_Step_Step_Property :: struct {
	name:  string,
	value: string,
}
// Java owners covered by this file:
//   - org.triplea.map.data.elements.GamePlay$Sequence$Step$StepProperty

game_play_sequence_step_step_property_get_name :: proc(self: ^Game_Play_Sequence_Step_Step_Property) -> string {
	return self.name
}

game_play_sequence_step_step_property_get_value :: proc(self: ^Game_Play_Sequence_Step_Step_Property) -> string {
	return self.value
}

