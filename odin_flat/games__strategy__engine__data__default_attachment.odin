package game

Default_Attachment :: struct {
	using game_data_component: Game_Data_Component,
	attached_to:               ^Attachable,
	name:                      string,
}

