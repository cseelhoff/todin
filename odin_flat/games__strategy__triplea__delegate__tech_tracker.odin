package game

Tech_Tracker :: struct {
	data:  ^Game_Data,
	cache: map[^Tech_Tracker_Key]any,
}

