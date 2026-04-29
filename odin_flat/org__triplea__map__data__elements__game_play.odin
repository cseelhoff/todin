package game

Game_Play :: struct {
	delegates: [dynamic]^Game_Play_Delegate,
	sequence:  ^Game_Play_Sequence,
	offset:    ^Game_Play_Offset,
}

Game_Play_Delegate :: struct {
	name:       string,
	java_class: string,
	display:    string,
}

Game_Play_Sequence :: struct {
	steps: [dynamic]^Game_Play_Sequence_Step,
}

Game_Play_Sequence_Step :: struct {
	name:            string,
	delegate:        string,
	player:          string,
	max_run_count:   ^i32,
	display:         string,
	step_properties: [dynamic]^Game_Play_Sequence_Step_Step_Property,
}

Game_Play_Sequence_Step_Step_Property :: struct {
	name:  string,
	value: string,
}

Game_Play_Offset :: struct {
	round: ^i32,
}
// Java owners covered by this file:
//   - org.triplea.map.data.elements.GamePlay

