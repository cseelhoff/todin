package game

Game_Play_Sequence_Step :: struct {
	name:            string,
	delegate:        string,
	player:          string,
	max_run_count:   ^i32,
	display:         string,
	step_properties: [dynamic]^Game_Play_Sequence_Step_Step_Property,
}

