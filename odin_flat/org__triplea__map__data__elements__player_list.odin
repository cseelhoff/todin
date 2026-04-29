package game

Map_Data_Player_List :: struct {
	players:   [dynamic]^Map_Data_Player_List_Player,
	alliances: [dynamic]^Map_Data_Player_List_Alliance,
}

Map_Data_Player_List_Player :: struct {
	name:            string,
	optional:        ^bool,
	can_be_disabled: ^bool,
	default_type:    string,
	is_hidden:       ^bool,
}

Map_Data_Player_List_Alliance :: struct {
	player:   string,
	alliance: string,
}

