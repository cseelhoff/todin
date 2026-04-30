package game

Game_Play_Sequence_Step_Step_Builder :: struct {
	name:            string,
	delegate:        string,
	player:          string,
	max_run_count:   ^i32,
	display:         string,
	step_properties: [dynamic]^Game_Play_Sequence_Step_Step_Property,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.GamePlay$Sequence$Step$StepBuilder

