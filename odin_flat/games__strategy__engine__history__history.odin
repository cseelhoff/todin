package game

History :: struct {
	using parent:      Default_Tree_Model,
	writer:            ^History_Writer,
	changes:           [dynamic]^Change,
	game_data:         ^Game_Data,
	panel:             ^History_Panel,
	next_change_index: i32,
	seeking_enabled:   bool,
}

